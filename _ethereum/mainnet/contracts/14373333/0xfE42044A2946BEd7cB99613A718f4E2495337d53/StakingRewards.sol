// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Math.sol";

import "./Utils.sol";

import "./IRewardEscrow.sol";
import "./IStakingRewards.sol";

/**
 * Contract which handles staking and accumulating rewards for addresses
 * Accounts stake their tokens in this contract and receive a reward token
 * based on the amount of time they have staked
 * The contract has a total reward token amount and rewards duration
 * At the end of the duration, the total reward amount is allocated
 * Addresses can claim their rewards at any time after initialization
 * Rewards can be escrowed after claiming
 * Contract handles arbitrary number of reward tokens
 */
contract StakingRewards is IStakingRewards, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    address[] public override rewardTokens; // Reward token addresses
    uint256 public override periodFinish = 0; // timestamp at which the rewards program ends
    uint256 public override rewardsDuration = 0; // rewards program duration
    mapping(address => uint256) public override lastUpdateTime; // last time the rewards have been updated

    // Reward token mapping to information for each token
    // Reward token address => RewardInformation
    mapping(address => RewardInformation) public override rewardInfo;

    bool public override rewardsAreEscrowed; // True if rewards are escrowed in RewardEscrow after unstaking

    IRewardEscrow public override rewardEscrow; // Vesting / Escrow contract address

    uint256 private _stakedTotalSupply; // Total supply of tokens staked in contract
    mapping(address => uint256) private _stakedBalances; // Individual address balances of staked tokens

    struct RewardInformation {
        uint256 rewardRate; // reward amount unlocked per second
        uint256 rewardPerTokenStored; // reward token amount per staked token amount
        uint256 totalRewardAmount; // total amount of rewards for the latest reward program
        uint256 remainingRewardAmount; // remaining amount of rewards in contract
        mapping(address => uint256) userRewardPerTokenPaid; // last stored user reward per staked token
        mapping(address => uint256) rewards; // last stored rewards for user
    }

    /* ========== VIEWS ========== */

    /**
     * Get total staked supply
     */
    function stakedTotalSupply() external view override returns (uint256) {
        return _stakedTotalSupply;
    }

    /**
     * Get staked balance of account
     */
    function stakedBalanceOf(address account)
        public
        view
        override
        returns (uint256)
    {
        return _stakedBalances[account];
    }

    /**
     * Check the last timestamp for which there are accumulated rewards
     */
    function lastTimeRewardApplicable() public view override returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /**
     * Get reward token amount per staked token rate
     * The rate is equal to:
     * seconds since reward init * reward token unlocked per second / total supply
     */
    function rewardPerToken(address token)
        public
        view
        override
        returns (uint256)
    {
        if (_stakedTotalSupply == 0) {
            return rewardInfo[token].rewardPerTokenStored;
        }
        return
            rewardInfo[token].rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime[token])
                    .mul(rewardInfo[token].rewardRate)
                    .mul(1e18)
                    .div(_stakedTotalSupply)
            );
    }

    /**
     * Check how much reward tokens an address has earned
     * @param account address to check for
     * @param token token to check for
     */
    function earned(address account, address token)
        public
        view
        override
        returns (uint256)
    {
        return
            _stakedBalances[account]
                .mul(
                    rewardPerToken(token).sub(
                        rewardInfo[token].userRewardPerTokenPaid[account]
                    )
                )
                .div(1e18)
                .add(rewardInfo[token].rewards[account]);
    }

    /**
     * Get total reward token amount for a given duration of time in seconds
     */
    function getRewardForDuration(address token)
        external
        view
        override
        returns (uint256)
    {
        return rewardInfo[token].rewardRate.mul(rewardsDuration);
    }

    /**
     * Get number of reward tokens
     */
    function getRewardTokensCount() external view override returns (uint256) {
        return rewardTokens.length;
    }

    /**
     * Get all reward tokens
     */
    function getRewardTokens()
        external
        view
        override
        returns (address[] memory tokens)
    {
        return rewardTokens;
    }

    /* ========== MUTATIVE ========== */

    /**
     * Stake rewards in contract
     * Only accounts for address that he has staked
     * @param amount amount of rewards to stake
     * @param sender address to stake rewards for
     */
    function stakeRewards(uint256 amount, address sender)
        internal
        nonReentrant
    {
        updateRewards(sender);
        _stakedTotalSupply = _stakedTotalSupply.add(amount);
        _stakedBalances[sender] = _stakedBalances[sender].add(amount);
        emit Staked(sender, amount);
    }

    /**
     * Withdraw rewards from contract
     * Only accounts for address balances internally
     * @param amount amount of rewards to unstake
     * @param sender address to unstake rewards for
     */
    function unstakeRewards(uint256 amount, address sender)
        internal
        nonReentrant
    {
        updateRewards(sender);
        _stakedTotalSupply = _stakedTotalSupply.sub(amount);
        _stakedBalances[sender] = _stakedBalances[sender].sub(amount);
        emit Withdrawn(sender, amount);
    }

    /**
     * Claim accumulated staking rewards
     */
    function claimReward() public override {
        updateRewards(msg.sender);
        for (uint256 i = 0; i < rewardTokens.length; ++i) {
            claimRewardForSingleToken(rewardTokens[i]);
        }
    }

    /**
     * Claim accumulated staking rewards for a single reward token
     * @param token reward token to claim rewards for
     */
    function claimRewardForSingleToken(address token) private {
        uint256 rewardAmount = earned(msg.sender, token);
        if (rewardAmount > 0) {
            if (rewardInfo[token].remainingRewardAmount < rewardAmount) {
                rewardInfo[token].rewards[msg.sender] = rewardAmount.sub(
                    rewardInfo[token].remainingRewardAmount
                );
                rewardAmount = rewardInfo[token].remainingRewardAmount;
            } else {
                rewardInfo[token].rewards[msg.sender] = 0;
            }

            // If there is a vesting period after reward claim
            // Escrow rewards for vesting period in "RewardEscrow" contract
            if (rewardsAreEscrowed) {
                IERC20(token).safeTransfer(address(rewardEscrow), rewardAmount);
                rewardEscrow.appendVestingEntry(
                    token,
                    msg.sender,
                    address(this),
                    rewardAmount
                );
                // Else transfer tokens directly to sender
            } else {
                IERC20(token).safeTransfer(msg.sender, rewardAmount);
            }
            rewardInfo[token].remainingRewardAmount = rewardInfo[token]
                .remainingRewardAmount
                .sub(rewardAmount);
            emit RewardClaimed(msg.sender, token, rewardAmount);
        }
    }

    /* ========== RESTRICTED ========== */

    /**
     * Initialize the rewards with a given reward amount
     * After calling this function, the rewards start accumulating
     * @param rewardAmount reward amount
     * @param token reward token
     */
    function initializeReward(uint256 rewardAmount, address token)
        public
        virtual
        override
    {
        updateRewards(address(0));
        RewardInformation storage rewardTokenInfo = rewardInfo[token];
        if (block.timestamp >= periodFinish) {
            rewardTokenInfo.rewardRate = rewardAmount.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardInfo[token].rewardRate);
            rewardTokenInfo.rewardRate = rewardAmount.add(leftover).div(
                rewardsDuration
            );
        }

        rewardTokenInfo.totalRewardAmount = rewardAmount;
        rewardTokenInfo.remainingRewardAmount = rewardTokenInfo
            .remainingRewardAmount
            .add(rewardAmount);
        lastUpdateTime[token] = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(rewardAmount);
    }

    /**
     * Configure the duration of the rewards
     * The rewards are unlocked based on the duration and the reward amount
     * @param _rewardsDuration reward duration in seconds
     */
    function setRewardsDuration(uint256 _rewardsDuration)
        public
        virtual
        override
    {
        require(
            _rewardsDuration > 0,
            "Rewards duration should be longer than 0"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /**
     * Update the accumulated rewards and reward per token for an account
     * Called on stake, unstake, claim and initialization of the rewards
     * @param account account to update rewards for
     */
    function updateRewards(address account) private {
        for (uint256 i = 0; i < rewardTokens.length; ++i) {
            updateReward(account, rewardTokens[i]);
        }
    }

    /**
     * Update the accumulated rewards and reward per token for an account
     * Updates only a single token
     * @param account account to update rewards for
     * @param token reward token
     */
    function updateReward(address account, address token) private {
        RewardInformation storage rewardTokenInfo = rewardInfo[token];
        rewardTokenInfo.rewardPerTokenStored = rewardPerToken(token);
        lastUpdateTime[token] = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewardTokenInfo.rewards[account] = earned(account, token);
            rewardTokenInfo.userRewardPerTokenPaid[account] = rewardTokenInfo
                .rewardPerTokenStored;
        }
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(
        address indexed user,
        address indexed token,
        uint256 rewardAmount
    );
    event RewardsDurationUpdated(uint256 newDuration);
}
