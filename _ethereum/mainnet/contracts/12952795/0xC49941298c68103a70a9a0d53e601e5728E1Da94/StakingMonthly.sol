// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./TwoStageOwnable.sol";
import "./StakingBase.sol";

contract StakingMonthly is StakingBase, TwoStageOwnable  {

    uint256 private _intervalDuration;
    uint256 private _rewardPool;
    uint256 private _totalStaked;
    mapping(address => StakeData[]) private _stakedInformation;

    function getTimestamp() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    /// @dev Deprecated: support for library compatibility
    function intervalsCount() public pure returns (uint256) {
        return 1;
    }

    /// @dev Deprecated: support for library compatibility
    function size() public pure returns (uint256) {
        return 0;
    }

    function freeSize() public view returns (uint256) {
        return _rewardPool.mul(100).div(revenue).sub(_totalStaked);
    }

    function intervalDuration() public view returns (uint256) {
        return _intervalDuration;
    }

    function requiredRewards() public view returns (uint256) {
        return _calculateRewards(_totalStaked);
    }

    function rewardPool() public view returns (uint256) {
        return _rewardPool;
    }

    function totalStaked() public view returns (uint256) {
        return _totalStaked;
    }

    function availableToWithdraw(address account, uint256 id) public view returns (uint256 amountToWithdraw) {
        StakeData storage stake_ = _getStake(account, id);
        if (stake_.startsAt.add(_intervalDuration) <= getTimestamp()) {
            amountToWithdraw = stake_.amount.add(stake_.rewards).sub(stake_.withdrawn);
        }
    }

    function getStake(address account, uint256 id) public view returns (StakeData memory) {
        return _getStake(account, id);
    }

    function getStakesCount(address account) public view returns (uint256) {
        return _stakedInformation[account].length;
    }

    function getStakes(
        address account,
        uint256 offset,
        uint256 limit
    ) public view returns (StakeData[] memory stakeData) {
        StakeData[] storage stakedInformation = _stakedInformation[account];
        uint256 stakedInformationLength = stakedInformation.length;
        uint256 to = offset.add(limit);
        if (stakedInformationLength < to) to = stakedInformationLength;
        stakeData = new StakeData[](to - offset);
        for (uint256 i = offset; i < to; i++) {
            stakeData[i - offset] = stakedInformation[stakedInformationLength - i - 1];
        }
    }

    constructor(
        address owner_,
        IERC20 stakingToken_,
        uint256 revenue_,
        uint256 intervalDuration_
    ) public TwoStageOwnable(owner_) {
        require(revenue_ > 0, "Revenue not positive");
        require(intervalDuration_ > 0, "IntervalDuration not positive");
        stakingToken = stakingToken_;
        revenue = revenue_;
        _intervalDuration = intervalDuration_ * 1 days;
    }

    function decreaseRewardPool(uint256 amount) external onlyOwner onlyPositiveAmount(amount) returns (bool) {
        address caller = msg.sender;
        uint256 requiredRewards_ = requiredRewards();
        require(_rewardPool > requiredRewards_, "No tokens to decrease");
        require(amount <= _rewardPool.sub(requiredRewards_), "Not enough amount");
        stakingToken.safeTransfer(caller, amount);
        _rewardPool = _rewardPool.sub(amount);
        emit RewardPoolDecreased(caller, amount);
        return true;
    }

    function increaseRewardPool(uint256 amount) external onlyOwner onlyPositiveAmount(amount) returns (bool) {
        address caller = msg.sender;
        stakingToken.safeTransferFrom(caller, address(this), amount);
        _rewardPool = _rewardPool.add(amount);
        emit RewardPoolIncreased(caller, amount);
        return true;
    }

    function setMinStakeAmount(uint256 value) external onlyOwner returns (bool) {
        minStakeAmount = value;
        emit MinStakeAmountUpdated(msg.sender, value);
        return true;
    }

    function stake(uint256 amount) external onlyPositiveAmount(amount) returns (bool) {
        address caller = msg.sender;
        uint256 rewards = _calculateRewards(amount);
        uint256 currentTimestamp = getTimestamp();
        uint256 stakeId = _stakedInformation[caller].length;
        _stakedInformation[caller].push();
        StakeData storage stake_ = _stakedInformation[caller][stakeId];
        bool canStake = true;
        if (stakeId > 0) {
            StakeData memory previousStake_ = _getStake(caller, stakeId.sub(1));
            canStake = previousStake_.startsAt.add(_intervalDuration) <= currentTimestamp;
        }
        require(amount >= minStakeAmount, "Amount lt minimum stake");
        require(rewards <= _rewardPool.sub(requiredRewards()), "Not enough rewards");
        require(canStake, "Previous stake is not over");
        _totalStaked = _totalStaked.add(amount);
        stake_.amount = amount;
        stake_.rewards = rewards;
        stake_.startsAt = currentTimestamp;
        stakingToken.safeTransferFrom(caller, address(this), amount);
        emit Staked(caller, stakeId, amount);
        return true;
    }

    function withdraw(uint256 id, uint256 amount) external onlyPositiveAmount(amount) returns (bool) {
        address caller = msg.sender;
        require(amount <= availableToWithdraw(caller, id), "Not enough available tokens");
        StakeData storage stake_ = _stakedInformation[caller][id];
        (uint256 rewardsSubValue, uint256 totalStakedSubValue) = _calculateWithdrawAmountParts(stake_, amount);
        _rewardPool = _rewardPool.sub(rewardsSubValue);
        _totalStaked = _totalStaked.sub(totalStakedSubValue);
        stake_.withdrawn = stake_.withdrawn.add(amount);
        stakingToken.safeTransfer(caller, amount);
        emit Withdrawn(caller, id, amount);
        return true;
    }

    function _calculateRewards(uint256 amount) internal view returns (uint256) {
        return amount.mul(revenue).div(100);
    }

    function _getStake(address account, uint256 id) internal view returns (StakeData storage) {
        require(id < _stakedInformation[account].length, "Invalid stake id");
        return _stakedInformation[account][id];
    }
}
