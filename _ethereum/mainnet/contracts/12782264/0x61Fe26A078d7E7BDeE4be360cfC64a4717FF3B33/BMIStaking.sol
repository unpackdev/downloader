// SPDX-License-Identifier: MIT
pragma solidity =0.7.4;

import "./OwnableUpgradeable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

import "./IContractsRegistry.sol";
import "./IBMIStaking.sol";

import "./ISTKBMIToken.sol";

contract BMIStaking is IBMIStaking, OwnableUpgradeable {
	using SafeMath for uint256;

	IERC20 public bmiToken;
	ISTKBMIToken public override stkBMIToken;
	uint256 public lastUpdateBlock;
	uint256 public rewardPerBlock;
	uint256 public totalPool;

	address public newBMIStakingAddress;

	event StakingMigrated(address staker, uint256 amount);

	modifier updateRewardPool() {
		if (totalPool == 0) {
			lastUpdateBlock = block.number;
		}
		
		totalPool = totalPool.add(_calculateReward());
		lastUpdateBlock = block.number;
		_;
	}	

	function __BMIStaking_init(uint256 _rewardPerBlock)
		external
		initializer
	{
		__Ownable_init();

		lastUpdateBlock = block.number;
		rewardPerBlock = _rewardPerBlock;
	}

	function setDependencies(IContractsRegistry _contractsRegistry) external onlyOwner {
		bmiToken = IERC20(_contractsRegistry.getBMIContract());
		stkBMIToken = ISTKBMIToken(_contractsRegistry.getSTKBMIContract());
	}

	function setNewBMIStaking(address _newBMIStakingAddress) external onlyOwner {
        newBMIStakingAddress = _newBMIStakingAddress;
    }

	function migrate() updateRewardPool external {
		require(newBMIStakingAddress != address(0), "Migrate: can't migrate to zero address");
		
		uint256 stakedBalance = stkBMIToken.balanceOf(_msgSender());

        require(stakedBalance > 0, "Migrate: balance is zero");

		uint256 amountBMI = _convertToBMI(stakedBalance);
		stkBMIToken.burn(_msgSender(), stakedBalance);

		totalPool = totalPool.sub(amountBMI);
		require(
			bmiToken.balanceOf(address(this)) >= amountBMI,
			"Withdraw: failed to transfer BMI tokens"
		);

        bmiToken.transfer(newBMIStakingAddress, amountBMI);

        (bool succ, ) =
            newBMIStakingAddress.call(
                abi.encodeWithSignature("stakeFor(address,uint256)", _msgSender(), amountBMI)
            );

        require(succ, "Something went wrong");

		emit StakingMigrated(_msgSender(), amountBMI);
    }

	function stake(uint256 _amountBMI) external override updateRewardPool {
		require(_amountBMI > 0, "Staking: cant stake 0 tokens");
		bmiToken.transferFrom(_msgSender(), address(this), _amountBMI);

		uint256 amountStkBMI = _convertToStkBMI(_amountBMI);
		stkBMIToken.mint(_msgSender(), amountStkBMI);

		totalPool = totalPool.add(_amountBMI);

		emit BMIStaked(_amountBMI, amountStkBMI, _msgSender());
	}

	function withdraw(uint256 _amountStkBMI) external override updateRewardPool {
		require(
			stkBMIToken.balanceOf(_msgSender()) >= _amountStkBMI,
			"Withdraw: not enough stkBMI tokens to withdraw"
		);

		uint256 amountBMI = _convertToBMI(_amountStkBMI);
		stkBMIToken.burn(_msgSender(), _amountStkBMI);

		totalPool = totalPool.sub(amountBMI);
		require(
			bmiToken.balanceOf(address(this)) >= amountBMI,
			"Withdraw: failed to transfer BMI tokens"
		);
		bmiToken.transfer(_msgSender(), amountBMI);

		emit BMIWithdrawn(amountBMI, _amountStkBMI, _msgSender());
	}

	function stakingReward(uint256 _amount) public view override returns (uint256) {
		return _convertToBMI(_amount);
	}

	function getStakedBMI(address _address) public view override returns (uint256) {
		uint256 balance = stkBMIToken.balanceOf(_address);
		return balance > 0 ? _convertToBMI(balance) : 0;
	}

	function setRewardPerBlock(uint256 _amount) external override onlyOwner updateRewardPool {
		rewardPerBlock = _amount;
	}

	function revokeUnusedRewardPool() external override onlyOwner updateRewardPool {
		uint256 contractBalance = bmiToken.balanceOf(address(this));

		require(
			contractBalance > totalPool,
			"There are no unused tokens to revoke"
		);

		uint256 unusedTokens = contractBalance.sub(totalPool);

		bmiToken.transfer(msg.sender, unusedTokens);
		emit UnusedRewardPoolRevoked(msg.sender, unusedTokens);
	}

	function _convertToStkBMI(uint256 _amount) internal view returns (uint256) {
		uint256 TSstkBMIToken = stkBMIToken.totalSupply();
		uint256 stakingPool = totalPool.add(_calculateReward());

		if (stakingPool > 0 && TSstkBMIToken > 0) {
			_amount = TSstkBMIToken.mul(_amount).div(stakingPool);
		}

		return _amount;
	}

	function _convertToBMI(uint256 _amount) internal view returns (uint256) {
		uint256 TSstkBMIToken = stkBMIToken.totalSupply();
		uint256 stakingPool = totalPool.add(_calculateReward());

		return TSstkBMIToken > 0 ? stakingPool.mul(_amount).div(TSstkBMIToken) : 0;
	}

	function _calculateReward() internal view returns (uint256) {
		uint256 blocksPassed = block.number.sub(lastUpdateBlock);
		return rewardPerBlock.mul(blocksPassed);
	}
}
