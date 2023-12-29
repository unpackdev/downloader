// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./IVipMembershipEligibilityChecker.sol";

error AmountIsZero();
error AmountGreaterThanStake();
error WithdrawalLocked();
error NoLockedTokens();
error StakingParametersChanged();

struct StakingWithLock {
    uint256 rewardsStartIndex;
    uint256 amount;
    uint256 lockedUntil;
}

/**
 * @dev This contract handles the internal logic and state of the stakings with lock. The users can lock their tokens
 * into the staking and they are only able to withdraw them after the `stakingLockPeriod`. By locking at least
 *  `vipMembershipThreshold` tokens, the user becomes eligible to mint VIP Membership NFT for free.
 * Actual transfers of tokens and distribution of rewards are handled in the main contract (`StakingPool`).
 */
abstract contract StakingPoolWithLock is IVipMembershipEligibilityChecker {
    uint256 public stakingLockPeriod;
    uint256 public vipMembershipThreshold;

    mapping(address => StakingWithLock) internal userStakingsWithLock;
    mapping(address => bool) internal userVipEligibility;

    event TokensStakedWithLock(address indexed user, uint256 amount);
    event LockedTokensWithdrawal(address indexed user, uint256 amount);
    event VipMembershipThresholdUpdated(uint256 newThreshold);
    event StakingLockPeriodUpdated(uint256 newLockPeriod);

    constructor(uint256 stakingLockPeriod_, uint256 vipMembershipThreshold_) {
        stakingLockPeriod = stakingLockPeriod_;
        vipMembershipThreshold = vipMembershipThreshold_;
    }

    /**
     * @dev Getter for the end of staking lock period. User cannot withdraw staked tokens
     * until the `stakingLockPeriod` is over.
     */
    function getStakeLockedUntil(address user) external view returns (uint256) {
        if (userStakingsWithLock[user].amount == 0) {
            revert NoLockedTokens();
        }

        return userStakingsWithLock[user].lockedUntil;
    }

    /**
     * @dev Function to check, whether the user is eligible for VIP Membership.
     */
    function getUserVipEligibility(address user) external view returns (bool) {
        return userVipEligibility[user];
    }

    /**
     * @dev Getter for current amount of locked tokens by user.
     */
    function getCurrentLockedStake(address user) public view returns (uint256) {
        return userStakingsWithLock[user].amount;
    }

    /**
     * @dev Function to stake tokens or to increase the existing stake. Locking new tokens will reset the staking lock period.
     * If user has already some tokens staked, the current rewards are calculated and saved to the `userBalances` mapping and
     * new staking is created with new total amount of tokens staked. Staking `rewardsStartIndex` points to the last unclaimable
     * reward in the `rewardsPerToken` array, which is the last index at the time of staking. Any new rewards that are added to
     * the array will be included in the reward calculation for this staking. The actual transfer of tokens is handled in the
     * main contract (`StakingPool`).
     */
    function _stakeTokensWithLock(
        uint256 amount,
        uint256 intendedStakingLockPeriod,
        uint256 intendedVipMembershipThreshold
    ) internal {
        if (intendedStakingLockPeriod != stakingLockPeriod || intendedVipMembershipThreshold != vipMembershipThreshold)
        {
            revert StakingParametersChanged();
        }

        StakingWithLock storage staking = userStakingsWithLock[msg.sender];
        uint256 stakedAmount = staking.amount;

        if (stakedAmount > 0) {
            _addRewardsToUserBalance(staking.rewardsStartIndex, staking.amount);
        }

        uint256 newStakedAmount = stakedAmount + amount;

        userStakingsWithLock[msg.sender] = StakingWithLock({
            rewardsStartIndex: _getLastRewardsIndex(),
            amount: newStakedAmount,
            lockedUntil: block.timestamp + stakingLockPeriod
        });

        if (newStakedAmount >= vipMembershipThreshold) {
            userVipEligibility[msg.sender] = true;
        }

        emit TokensStakedWithLock(msg.sender, amount);
    }

    /**
     * @dev Function to withdraw staked tokens and decrease the existing stake. The current rewards are calculated and saved to the `userBalances`
     * mapping and new staking is created with the remaining amount of staked tokens. This function does not transfer rewards (ETH) to the user,
     * they remain in the contract and can be withdrawn by calling `withdrawRewards` function. The actual transfer of tokens is handled in the
     * main contract (`StakingPool`).
     */
    function _handleLockedTokensWithdrawal(uint256 amount) internal {
        if (amount == 0) {
            revert AmountIsZero();
        }

        StakingWithLock storage staking = userStakingsWithLock[msg.sender];

        if (block.timestamp < staking.lockedUntil) {
            revert WithdrawalLocked();
        }
        if (amount > staking.amount) {
            revert AmountGreaterThanStake();
        }

        _addRewardsToUserBalance(staking.rewardsStartIndex, staking.amount);

        staking.rewardsStartIndex = _getLastRewardsIndex();
        staking.amount -= amount;

        emit LockedTokensWithdrawal(msg.sender, amount);
    }

    /**
     * @dev Setters for staking with lock parameters. Permissions and update lock is handled in the main contract (`StakingPool`).
     */
    function _updateVipMembershipThreshold(uint256 newThreshold) internal {
        vipMembershipThreshold = newThreshold;
        emit VipMembershipThresholdUpdated(newThreshold);
    }

    function _updateStakingLockPeriod(uint256 newLockPeriod) internal {
        stakingLockPeriod = newLockPeriod;
        emit StakingLockPeriodUpdated(newLockPeriod);
    }

    /**
     * @dev Returns last index of the `rewardsPerToken` array.
     */
    function _getLastRewardsIndex() internal view virtual returns (uint256);

    /**
     * @dev Function to add the existing rewards to the user balance, in case the user has changed the amount of staked tokens.
     */
    function _addRewardsToUserBalance(uint256 startIndex, uint256 amount) internal virtual;
}
