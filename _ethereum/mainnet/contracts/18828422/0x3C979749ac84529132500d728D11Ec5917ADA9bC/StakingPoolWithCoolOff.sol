// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

error AmountIsZero();
error AmountGreaterThanStake();
error WithdrawalLocked();
error WithdrawalNotInProgress();
error AnotherWithdrawalInProgress();

struct StakingWithCoolOff {
    uint256 rewardsStartIndex;
    uint256 amount;
}

struct Withdrawal {
    uint256 amount;
    uint256 coolOffEnd;
}

/**
 * @dev This contract handles the internal logic and state of the stakings with cool-off period. The users are able to stake,
 * unstake and update the amount of staked tokens, but they are only able to withdraw staked tokens after the cool-off
 * period (by default 48 hours) after unstaking. Actual transfers of tokens and distribution of rewards are handled in
 * the main contract (`StakingPool`).
 */
abstract contract StakingPoolWithCoolOff {
    uint256 public immutable coolOffPeriod;

    mapping(address => StakingWithCoolOff) internal userStakingsWithCoolOff;
    mapping(address => Withdrawal) internal userWithdrawals;

    event TokensStakedWithCoolOff(address indexed user, uint256 amount);
    event TokensUnstakedWithCoolOff(address indexed user, uint256 amount);
    event StakedTokensWithdrawn(address indexed user, uint256 amount);

    constructor(uint256 coolOffPeriod_) {
        coolOffPeriod = coolOffPeriod_;
    }

    /**
     * @dev Getter for the end of cool-off period.
     */
    function getCoolOffPeriodEnd(address user) external view returns (uint256) {
        if (userWithdrawals[user].amount == 0) {
            revert WithdrawalNotInProgress();
        }

        return userWithdrawals[user].coolOffEnd;
    }

    /**
     * @dev Getter for the amount of unstaked tokens.
     */
    function getUnstakedAmountWithCoolOff(address user) external view returns (uint256) {
        return userWithdrawals[user].amount;
    }

    /**
     * @dev Getter for current amount of staked tokens by user though the staking with cool-off period.
     */
    function getCurrentStakeWithCoolOff(address user) public view returns (uint256) {
        return userStakingsWithCoolOff[user].amount;
    }

    /**
     * @dev Function to stake tokens with cool-off or to increase the existing stake. If user has already
     * some tokens staked, the current rewards are calculated and saved to the `userBalances` mapping and
     * new staking is created with new total amount of tokens staked. Staking `rewardsStartIndex` points
     * to the last unclaimable reward in the `rewardsPerToken` array, which is the last index at the time
     * of staking. Any new rewards that are added to the array will be included in the reward calculation
     * for this staking. The actual transfer of tokens is handled in the main contract (`StakingPool`).
     */
    function _stakeTokensWithCoolOff(uint256 amount) internal {
        StakingWithCoolOff storage staking = userStakingsWithCoolOff[msg.sender];
        uint256 stakedAmount = staking.amount;

        if (stakedAmount > 0) {
            _addRewardsToUserBalance(staking.rewardsStartIndex, staking.amount);
        }

        userStakingsWithCoolOff[msg.sender] =
            StakingWithCoolOff({rewardsStartIndex: _getLastRewardsIndex(), amount: stakedAmount + amount});

        emit TokensStakedWithCoolOff(msg.sender, amount);
    }

    /**
     * @dev Function to trigger withdrawal of staked tokens and decrease the existing stake. Calling this function will start the cool-off
     * period, after which the user can transfer the tokens to his wallet with the `withdrawUnstakedTokens` function. The current rewards
     * are calculated and saved to the `userBalances` mapping and new staking is created with the remaining amount of staked tokens.
     */
    function _unstakeTokensWithCoolOff(uint256 amount) internal virtual {
        if (amount == 0) {
            revert AmountIsZero();
        }

        StakingWithCoolOff storage staking = userStakingsWithCoolOff[msg.sender];

        if (userWithdrawals[msg.sender].amount > 0) {
            revert AnotherWithdrawalInProgress();
        }
        if (staking.amount < amount) {
            revert AmountGreaterThanStake();
        }

        _addRewardsToUserBalance(staking.rewardsStartIndex, staking.amount);

        staking.rewardsStartIndex = _getLastRewardsIndex();
        staking.amount -= amount;

        userWithdrawals[msg.sender] = Withdrawal({amount: amount, coolOffEnd: block.timestamp + coolOffPeriod});

        emit TokensUnstakedWithCoolOff(msg.sender, amount);
    }

    /**
     * @dev Function to update internal state before the tokens are transferred to the user wallet.
     * This function is called by the main contract in the `withdrawUnstakedTokens` function.
     */
    function _prepareTokensWithdrawal(address user) internal returns (uint256) {
        Withdrawal storage withdrawal = userWithdrawals[user];
        uint256 amount = withdrawal.amount;

        if (amount == 0) {
            revert WithdrawalNotInProgress();
        }
        if (block.timestamp < withdrawal.coolOffEnd) {
            revert WithdrawalLocked();
        }

        delete userWithdrawals[user];

        emit StakedTokensWithdrawn(user, amount);

        return amount;
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
