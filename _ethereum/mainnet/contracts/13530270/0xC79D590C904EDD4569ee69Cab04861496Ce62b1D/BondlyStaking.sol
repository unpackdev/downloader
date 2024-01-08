// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

import "./IxBondlyToken.sol";
import "./IBondlyStaking.sol";

contract BondlyStaking is IBondlyStaking, OwnableUpgradeable {
	using SafeMathUpgradeable for uint256;

	IERC20 public bondlyToken;
	IxBondlyToken public override xBondlyToken;
	uint256 public lastUpdateBlock;
	uint256 public rewardPerBlock;
	uint256 public totalPool;

	modifier updateRewardPool() {
		if (totalPool == 0) {
			lastUpdateBlock = block.number;
		}
		else{
			uint256 rewardToAdd;
			(rewardToAdd, lastUpdateBlock) = _calculateReward();
			totalPool = totalPool.add(rewardToAdd);
		}
		_;
	}

	function initialize(uint256 _rewardPerBlock, address _bondly, address _xbondly)
		external
		initializer
	{
		__Ownable_init();

		lastUpdateBlock = block.number;
		rewardPerBlock = _rewardPerBlock;

		bondlyToken = IERC20(_bondly);
		xBondlyToken = IxBondlyToken(_xbondly);
	}

	function stake(uint256 _amountBONDLY) external override updateRewardPool {
		require(_amountBONDLY > 0, "Staking: cant stake 0 tokens");
		bondlyToken.transferFrom(_msgSender(), address(this), _amountBONDLY);

		uint256 amountxBONDLY = _convertToxBONDLY(_amountBONDLY);
		xBondlyToken.mint(_msgSender(), amountxBONDLY);

		totalPool = totalPool.add(_amountBONDLY);

		emit StakedBONDLY(_amountBONDLY, amountxBONDLY, _msgSender());
	}

	function withdraw(uint256 _amountxBONDLY) external override updateRewardPool {
		require(
			xBondlyToken.balanceOf(_msgSender()) >= _amountxBONDLY,
			"Withdraw: not enough xBONDLY tokens to withdraw"
		);

		uint256 amountBONDLY = _convertToBONDLY(_amountxBONDLY);
		xBondlyToken.burn(_msgSender(), _amountxBONDLY);

		totalPool = totalPool.sub(amountBONDLY);
		require(
			bondlyToken.balanceOf(address(this)) >= amountBONDLY,
			"Withdraw: failed to transfer BONDLY tokens"
		);
		bondlyToken.transfer(_msgSender(), amountBONDLY);

		emit WithdrawnBONDLY(amountBONDLY, _amountxBONDLY, _msgSender());
	}

	function stakingReward(uint256 _amount) public view override returns (uint256) {
		return _convertToBONDLY(_amount);
	}

	function getStakedBONDLY(address _address) public view override returns (uint256) {
		uint256 balance = xBondlyToken.balanceOf(_address);
		return balance > 0 ? _convertToBONDLY(balance) : 0;
	}

	function setRewardPerBlock(uint256 _amount) external override onlyOwner updateRewardPool {
		rewardPerBlock = _amount;
	}

	function revokeUnusedRewardPool() external override onlyOwner updateRewardPool {
		uint256 contractBalance = bondlyToken.balanceOf(address(this));

		require(
			contractBalance > totalPool,
			"There are no unused tokens to revoke"
		);

		uint256 unusedTokens = contractBalance.sub(totalPool);

		bondlyToken.transfer(msg.sender, unusedTokens);
		emit UnusedRewardPoolRevoked(msg.sender, unusedTokens);
	}

	function _convertToxBONDLY(uint256 _amount) internal view returns (uint256) {
		uint256 TSxBondlyToken = xBondlyToken.totalSupply();
		(uint256 outstandingReward,) = _calculateReward();
		uint256 stakingPool = totalPool.add(outstandingReward);

		if (stakingPool > 0 && TSxBondlyToken > 0) {
			_amount = TSxBondlyToken.mul(_amount).div(stakingPool);
		}

		return _amount;
	}

	function _convertToBONDLY(uint256 _amount) internal view returns (uint256) {
		uint256 TSxBondlyToken = xBondlyToken.totalSupply();
		(uint256 outstandingReward,) = _calculateReward();
		uint256 stakingPool = totalPool.add(outstandingReward);

		return stakingPool.mul(_amount).div(TSxBondlyToken);
	}

	function _calculateReward() internal view returns (uint256, uint256) {
		uint256 blocksPassed = block.number.sub(lastUpdateBlock);
		uint256 updateBlock = block.number;
		uint256 blocksWithRewardFunding = (bondlyToken.balanceOf(address(this)).sub(totalPool)).div(rewardPerBlock);
		if(blocksPassed > blocksWithRewardFunding){
			blocksPassed = blocksWithRewardFunding;
			updateBlock = lastUpdateBlock.add(blocksWithRewardFunding);
		}
		return (rewardPerBlock.mul(blocksPassed), updateBlock);
	}
	function _calculateAPR() public view returns (uint256) {
		(uint256 outstandingReward, uint256 newestBlockWithRewards) = _calculateReward();

		if(newestBlockWithRewards != block.number){
			return 0; // Pool is out of rewards
		}
		uint256 stakingPool = totalPool.add(outstandingReward);
		if (stakingPool == 0)
			return 0;
		uint256 SECONDS_PER_YEAR = 31536000;
		uint256 SECONDS_PER_BLOCK = 13;
		return rewardPerBlock.mul(1e18).div(stakingPool).mul(SECONDS_PER_YEAR).div(SECONDS_PER_BLOCK).mul(100);
	}
}
