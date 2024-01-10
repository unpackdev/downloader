// SPDX-License-Identifier: MIT
pragma solidity 0.6.2;

import "./OwnableUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IStakingPoolRewarder.sol";
import "./TransferHelper.sol";

/**
 * @title StakingPoolRewarder
 *
 * @dev An upgradeable rewarder contract for releasing Lithium tokens based on
 * schedule.
 */
contract StakingPoolRewarder is OwnableUpgradeable, IStakingPoolRewarder {
    using SafeMathUpgradeable for uint256;

    event VestingScheduleAdded(address indexed user, uint256 amount, uint256 startTime, uint256 endTime, uint256 step);
    event VestingSettingChanged(uint8 percentageToVestingSchedule, uint256 claimStartTime, uint256 claimDuration, uint256 claimStep);
    event TokenVested(address indexed user, uint256 poolId, uint256 amount);
    event MoveVestingScheduleEarlier(uint256 poolId, address indexed user, uint32 startTime, uint32 endTime, uint256 duration);
    event RewardDispatcherUpdated(address indexed dispatcher);

    /**
     * @param amount Total amount to be vested over the complete period
     * @param startTime Unix timestamp in seconds for the period start time
     * @param endTime Unix timestamp in seconds for the period end time
     * @param step Interval in seconds at which vestable amounts are accumulated
     * @param lastClaimTime Unix timestamp in seconds for the last claim time
     */
    struct VestingSchedule {
        uint128 amount;
        uint32 startTime;
        uint32 endTime;
        uint32 step;
        uint32 lastClaimTime;
    }

    mapping(address => mapping(uint256 => VestingSchedule)) public vestingSchedules;
    address public stakingPools;
    address public rewardToken;
    address public rewardDispatcher;
    uint8 public percentageToVestingSchedule;
    uint256 public claimStartTime;
    uint256 public claimDuration;
    uint256 public claimStep;
    bool private locked;

    modifier blockReentrancy {
        require(!locked, "Reentrancy is blocked");
        locked = true;
        _;
        locked = false;
    }

    function __StakingPoolRewarder_init(
        address _stakingPools,
        address _rewardToken,
        address _rewardDispatcher,
        uint8 _percentageToVestingSchedule,
        uint256 _claimStartTime,
        uint256 _claimDuration,
        uint256 _claimStep
    ) public initializer {
        __Ownable_init();
        require(_stakingPools != address(0), "StakingPoolRewarder: stakingPools zero address");
        require(_rewardToken != address(0), "StakingPoolRewarder: rewardToken zero address");
        require(_rewardDispatcher != address(0), "StakingPoolRewarder: rewardDispatcher zero address");
        require(_percentageToVestingSchedule <= 100, "StakingPoolRewarder: invalid percentageToVestingSchedule value");
        require(_claimStep > 0 && _claimDuration % _claimStep == 0, "StakingPoolRewarder: invalid step");

        stakingPools = _stakingPools;
        rewardToken = _rewardToken;
        rewardDispatcher = _rewardDispatcher;

        percentageToVestingSchedule = _percentageToVestingSchedule;
        claimStartTime = _claimStartTime;
        claimDuration = _claimDuration;
        claimStep = _claimStep;
    }

    modifier onlyStakingPools() {
        require(stakingPools == msg.sender, "StakingPoolRewarder: only stakingPool can call");
        _;
    }

    function updateVestingSetting(
        uint8 _percentageToVestingSchedule,
        uint256 _claimStartTime,
        uint256 _claimDuration,
        uint256 _claimStep
    ) external onlyOwner {
        require(_percentageToVestingSchedule <= 100, "StakingPoolRewarder: invalid percentageToVestingSchedule value");
        require(_claimStep > 0 && _claimDuration % _claimStep == 0, "StakingPoolRewarder: invalid step");
        percentageToVestingSchedule = _percentageToVestingSchedule;
        claimStartTime = _claimStartTime;
        claimDuration = _claimDuration;
        claimStep = _claimStep;
        emit VestingSettingChanged(_percentageToVestingSchedule, _claimStartTime, _claimDuration, _claimStep);
    }

    function moveVestingScheduleEarlier(uint256 poolId, address user, uint256 duration) external onlyOwner {
        require(user != address(0), "StakingPoolRewarder: zero address");
        require(vestingSchedules[user][poolId].amount != 0, "StakingPoolRewarder: Vesting schedule not exist" );
        VestingSchedule memory vestingSchedule = vestingSchedules[user][poolId];
        vestingSchedules[user][poolId] = VestingSchedule({
        amount : vestingSchedule.amount,
        startTime : uint32(uint256(vestingSchedule.startTime).sub(duration)),
        endTime : uint32(uint256(vestingSchedule.endTime).sub(duration)),
        step : vestingSchedule.step,
        lastClaimTime : uint32(uint256(vestingSchedule.lastClaimTime).sub(duration))
        });
        emit MoveVestingScheduleEarlier(poolId, user, vestingSchedules[user][poolId].startTime, vestingSchedules[user][poolId].endTime, duration);
    }

    function setRewardDispatcher(address _rewardDispatcher) external onlyOwner {
        require(_rewardDispatcher != address(0), "StakingPoolRewarder: zero address!");
        rewardDispatcher = _rewardDispatcher;
        emit RewardDispatcherUpdated(_rewardDispatcher);
    }

    function updateVestingSchedule(
        address user,
        uint256 poolId,
        uint256 amount,
        uint256 startTime,
        uint256 endTime,
        uint256 step
    ) private {
        require(user != address(0), "StakingPoolRewarder: zero address");
        require(amount > 0, "StakingPoolRewarder: zero amount");
        require(startTime < endTime, "StakingPoolRewarder: invalid time range");
        require(step > 0 && endTime.sub(startTime) % step == 0, "StakingPoolRewarder: invalid step");

        // Overflow checks
        require(uint256(uint128(amount)) == amount, "StakingPoolRewarder: amount overflow");
        require(uint256(uint32(startTime)) == startTime, "StakingPoolRewarder: startTime overflow");
        require(uint256(uint32(endTime)) == endTime, "StakingPoolRewarder: endTime overflow");
        require(uint256(uint32(step)) == step, "StakingPoolRewarder: step overflow");

        vestingSchedules[user][poolId] = VestingSchedule({
        amount : uint128(amount),
        startTime : uint32(startTime),
        endTime : uint32(endTime),
        step : uint32(step),
        lastClaimTime : uint32(startTime)
        });

        emit VestingScheduleAdded(user, amount, startTime, endTime, step);
    }

    function calculateWithdrawableFromVesting(address user, uint256 poolId) external view returns (uint256) {
        (uint256 withdrawable, ,) = _calculateWithdrawableFromVesting(user, poolId);
        return withdrawable;
    }

    function _calculateWithdrawableFromVesting(address user, uint256 poolId) private view returns (
        uint256 amount,
        uint256 newClaimTime,
        bool allVested
    ){

        VestingSchedule memory vestingSchedule = vestingSchedules[user][poolId];
        if (vestingSchedule.amount == 0) return (0, 0, false);
        if (block.timestamp < uint256(vestingSchedule.startTime)) return (0, 0, false);

        uint256 currentStepTime =
        MathUpgradeable.min(
            block.timestamp
            .sub(uint256(vestingSchedule.startTime))
            .div(uint256(vestingSchedule.step))
            .mul(uint256(vestingSchedule.step))
            .add(uint256(vestingSchedule.startTime)),
            uint256(vestingSchedule.endTime)
        );

        if (currentStepTime <= uint256(vestingSchedule.lastClaimTime)) return (0, 0, false);

        uint256 totalSteps =
        uint256(vestingSchedule.endTime).sub(uint256(vestingSchedule.startTime)).div(vestingSchedule.step);

        if (currentStepTime == uint256(vestingSchedule.endTime)) {
            // All vested

            uint256 stepsVested =
             uint256(vestingSchedule.lastClaimTime).sub(uint256(vestingSchedule.startTime)).div(vestingSchedule.step);
            uint256 amountToVest =
             uint256(vestingSchedule.amount).sub(uint256(vestingSchedule.amount).div(totalSteps).mul(stepsVested));
            return (amountToVest, currentStepTime, true);
        } else {
            // Partially vested
            uint256 stepsToVest = currentStepTime.sub(uint256(vestingSchedule.lastClaimTime)).div(vestingSchedule.step);
            uint256 amountToVest = uint256(vestingSchedule.amount).div(totalSteps).mul(stepsToVest);
            return (amountToVest, currentStepTime, false);
        }
    }

    function _calculateUnvestedAmount(address user, uint256 poolId, uint256 stepTime) private view returns (uint256) {
        if (vestingSchedules[user][poolId].amount == 0) return 0;
        
        uint256 totalSteps =
            uint256(vestingSchedules[user][poolId].endTime)
            .sub(uint256(vestingSchedules[user][poolId].startTime))
            .div(vestingSchedules[user][poolId].step);
        uint256 stepsVested =
            stepTime
            .sub(uint256(vestingSchedules[user][poolId].startTime))
            .div(vestingSchedules[user][poolId].step);
        return uint256(vestingSchedules[user][poolId].amount)
            .sub(uint256(vestingSchedules[user][poolId].amount)
            .mul(stepsVested)
            .div(totalSteps));
    }

    function onReward(
        uint256 poolId,
        address user,
        uint256 amount
    ) onlyStakingPools external override {
        _onReward(poolId, user, amount);
    }

    function _onReward(uint256 poolId, address user, uint256 amount) private blockReentrancy {
        require(user != address(0), "StakingPoolRewarder: zero address");

        uint256 newUnvestedAmount = 0;
        uint256 newVestedAmount = 0;
        if (amount > 0) {
            newUnvestedAmount = amount.mul(uint256(percentageToVestingSchedule)).div(100);
            newVestedAmount = amount.sub(newUnvestedAmount);
        }

        if (newUnvestedAmount > 0) {
            require(vestingSchedules[user][poolId].amount == 0, "StakingPoolRewarder: vesting schedule already exists");
            updateVestingSchedule(user, poolId, newUnvestedAmount,
                claimStartTime,
                claimStartTime.add(claimDuration),
                claimStep);
        }

        (uint256 lastVestedAmount,uint256 newClaimTime, bool allVested) = 
            _calculateWithdrawableFromVesting(user, poolId);

        if (lastVestedAmount > 0) {
            if (allVested) {
                // Remove storage slot to save gas
                delete vestingSchedules[user][poolId];
            } else {
                vestingSchedules[user][poolId].lastClaimTime = uint32(newClaimTime);
            } 
        }

        uint256 totalVested = lastVestedAmount.add(newVestedAmount);
        require(totalVested > 0, "StakingPoolRewarder: zero totalVested");
        TransferHelper.safeTransferFrom(
            rewardToken,
            rewardDispatcher,
            user,
            totalVested
        );
        emit TokenVested(user, poolId, totalVested);
    }
    
    // Add an external function to enable user claim vested reward when reward amount in staking is 0
    function claimVestedReward(uint256 poolId) external {
        require(poolId > 0, "StakingPoolRewarder: poolId is 0");

        _onReward(poolId, msg.sender, 0);
    }

}