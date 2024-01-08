// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./OwnableUpgradeable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

import "./IContractsRegistry.sol";
import "./IBrightStaking.sol";

import "./ISTKBrightToken.sol";
import "./IERC20Permit.sol";
import "./Globals.sol";
import "./AbstractCooldownStaking.sol";

contract BrightStaking is IBrightStaking, AbstractCooldownStaking, OwnableUpgradeable {
	using SafeMath for uint256;

	IERC20 public brightToken;
	ISTKBrightToken public override stkBrightToken;
	uint256 public lastUpdateBlock;
	uint256 public rewardPerBlock;
	uint256 public totalPool;

	modifier updateRewardPool() {
		if (totalPool == 0) {
			lastUpdateBlock = block.number;
		}

		totalPool = totalPool.add(_calculateReward());
		lastUpdateBlock = block.number;
		_;
	}

	receive() payable external {
		revert('BrightStk: No ETH here');
	}

	function __BrightStaking_init(uint256 _rewardPerBlock, IContractsRegistry _contractsRegistry)
		external
		initializer
	{
		__Ownable_init();

		rewardPerBlock = _rewardPerBlock;

		brightToken = IERC20(_contractsRegistry.getBrightContract());
		stkBrightToken = ISTKBrightToken(_contractsRegistry.getSTKBrightContract());
	}

	function stake(uint256 _amountBright) external override updateRewardPool {
		brightToken.transferFrom(_msgSender(), address(this), _amountBright);

        _stake(_msgSender(), _amountBright);
	}

	/**
	 * @dev Caller is the actual staker but stakes for _user
	 */
	function stakeFor(address _user, uint256 _amountBright) external override updateRewardPool {
		brightToken.transferFrom(_msgSender(), address(this), _amountBright);

		_stake(_user, _amountBright);
	}

    function stakeWithPermit(uint256 _amountBright, uint8 _v, bytes32 _r, bytes32 _s) external override updateRewardPool{
        IERC20Permit(address(brightToken)).permit(
            _msgSender(),
            address(this),
            _amountBright,
            MAX_INT,
            _v,
            _r,
            _s
        );

		brightToken.transferFrom(_msgSender(), address(this), _amountBright);
        _stake(_msgSender(), _amountBright);
    }

    function _stake(address _staker, uint256 _amountBright) internal {
		require(_amountBright > 0, "BrightStk: cant stake 0 tokens");
        uint256 amountStkBright = _convertToStkBright(_amountBright);
        stkBrightToken.mint(_staker, amountStkBright);

        totalPool = totalPool.add(_amountBright);

        emit StakedBright(_amountBright, amountStkBright, _staker);
    }

	function callWithdraw(uint256 _amountStkBrightUnlock) external override {
		require(_amountStkBrightUnlock > 0, "BrightStk: can't unlock 0 tokens");

		require(
			stkBrightToken.balanceOf(_msgSender()) >= _amountStkBrightUnlock,
			"BrightStk: not enough stkBright to unlock"
		);

		withdrawalsInfo[_msgSender()] = WithdrawalInfo(
			block.timestamp.add(WITHDRAWING_COOLDOWN_DURATION),
			_amountStkBrightUnlock
		);
	}

	function withdraw() external override updateRewardPool {
		uint256 _whenCanWithdrawBrightReward = whenCanWithdrawBrightReward(_msgSender());
		require(_whenCanWithdrawBrightReward != 0, "BrightStk: unlock not started/exp");
		require(_whenCanWithdrawBrightReward <= block.timestamp, "BrightStk: cooldown not reached");

		uint256 _amountStkBright = withdrawalsInfo[_msgSender()].amount;
		delete withdrawalsInfo[_msgSender()];

		require(
			stkBrightToken.balanceOf(_msgSender()) >= _amountStkBright,
			"BrightStk: not enough stkBright tokens to withdraw"
		);

		uint256 amountBright = _convertToBright(_amountStkBright);
		require(
			brightToken.balanceOf(address(this)) >= amountBright,
			"BrightStk: not enough Bright tokens in the pool"
		);
		stkBrightToken.burn(_msgSender(), _amountStkBright);

		totalPool = totalPool.sub(amountBright);

		brightToken.transfer(_msgSender(), amountBright);

		emit WithdrawnBright(amountBright, _amountStkBright, _msgSender());
	}

	function stakingReward(uint256 _amount) external view override returns (uint256) {
		return _convertToBright(_amount);
	}

	function getStakedBright(address _address) external view override returns (uint256) {
		uint256 balance = stkBrightToken.balanceOf(_address);
		return balance > 0 ? _convertToBright(balance) : 0;
	}

	function setRewardPerBlock(uint256 _amount) external override onlyOwner updateRewardPool {
		rewardPerBlock = _amount;
	}

	function sweepUnusedRewards() external override onlyOwner updateRewardPool {
		uint256 contractBalance = brightToken.balanceOf(address(this));

		require(
			contractBalance > totalPool,
			"BrightStk: There are no unused tokens to revoke"
		);

		uint256 unusedTokens = contractBalance.sub(totalPool);

		brightToken.transfer(_msgSender(), unusedTokens);
		emit SweepedUnusedRewards(_msgSender(), unusedTokens);
	}

	function outstandingRewards() external view returns (uint256) {
		return _calculateReward();
	}

	function _convertToStkBright(uint256 _amount) internal view returns (uint256) {
		uint256 tStkBrightToken = stkBrightToken.totalSupply();
		uint256 stakingPool = totalPool.add(_calculateReward());

		if (stakingPool > 0 && tStkBrightToken > 0) {
			_amount = tStkBrightToken.mul(_amount).div(stakingPool);
		}

		return _amount;
	}

	function _convertToBright(uint256 _amount) internal view returns (uint256) {
		uint256 tStkBrightToken = stkBrightToken.totalSupply();
		uint256 stakingPool = totalPool.add(_calculateReward());

		return tStkBrightToken > 0 ? stakingPool.mul(_amount).div(tStkBrightToken) : 0;
	}

	function _calculateReward() internal view returns (uint256) {
		uint256 blocksPassed = block.number.sub(lastUpdateBlock);
		return rewardPerBlock.mul(blocksPassed);
	}
}
