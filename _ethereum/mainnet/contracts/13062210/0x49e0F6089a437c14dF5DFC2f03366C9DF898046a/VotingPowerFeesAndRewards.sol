// SPDX-License-Identifier: None
pragma solidity 0.6.12;

import "./Math.sol";
import "./IRewardDistributionRecipient.sol";
import "./VotingPowerFees.sol";

/// @title Rewards functionality for the voting power.
/// @notice Rewards are paid by some centralized treasury.
/// Then this contract distributes rewards to the voting power holders.
contract VotingPowerFeesAndRewards is IRewardDistributionRecipient, VotingPowerFees{
    uint256 internal constant DURATION = 7 days;

    uint256 internal periodFinish = 0;

    uint256 internal rewardRate = 0;

    IERC20 internal rewardsToken;

    uint256 internal lastUpdateTime;

    uint256 internal rewardPerTokenStored;

    mapping(address => uint256) internal userRewardPerTokenPaid;

    mapping(address => uint256) internal rewards;

    /// @notice Returns DURATION value
    /// @return _DURATION - uint256 value
    function getDuration() external pure returns (uint256 _DURATION) {
        return DURATION;
    }

    /// @notice Returns periodFinish value
    /// @return _periodFinish - uint256 value
    function getPeriodFinish() external view returns (uint256 _periodFinish) {
        return periodFinish;
    }

    /// @notice Returns rewardRate value
    /// @return _rewardRate - uint256 value
    function getRewardRate() external view returns (uint256 _rewardRate) {
        return rewardRate;
    }

    /// @notice Returns rewardsToken value
    /// @return _rewardsToken - IERC20 value
    function getRewardsToken() external view returns (IERC20 _rewardsToken) {
        return rewardsToken;
    }

    /// @notice Returns lastUpdateTime value
    /// @return _lastUpdateTime - uint256 value
    function getLastUpdateTime() external view returns (uint256 _lastUpdateTime) {
        return lastUpdateTime;
    }

    /// @notice Returns rewardPerTokenStored value
    /// @return _rewardPerTokenStored - uint256 value
    function getRewardPerTokenStored() external view returns (uint256 _rewardPerTokenStored) {
        return rewardPerTokenStored;
    }

    /// @notice Returns user's reward per token paid
    /// @param _user address of the user for whom data are requested
    /// @return _userRewardPerTokenPaid - uint256 value
    function getUserRewardPerTokenPaid(address _user) external view returns (uint256 _userRewardPerTokenPaid) {
        return userRewardPerTokenPaid[_user];
    }

    /// @notice Returns user's available rewards
    /// @param _user address of the user for whom data are requested
    /// @return _rewards - uint256 value
    function getRewards(address _user) external view returns (uint256 _rewards) {
        return rewards[_user];
    }

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    /// @notice Contract's constructor
    /// @param _stakingToken Sets staking token
    /// @param _feesToken Sets fees token
    /// @param _rewardsToken Sets rewards token
    constructor(
        IERC20 _stakingToken,
        IERC20 _feesToken,
        IERC20 _rewardsToken
    ) public VotingPowerFees(_stakingToken, _feesToken) {
        rewardsToken = _rewardsToken;
    }

    /// @notice Claims reward for user
    /// @param account user for which to claim
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /// @notice Return timestamp last time reward applicable
    /// @return lastTimeRewardApplicable - uint256
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /// @notice Returns reward per full (10^18) token.
    /// @return rewardPerToken - uint256
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(totalSupply())
            );
    }

    /// @notice Returns earned reward fot account
    /// @param account user for which reward amount is requested
    /// @return earned - uint256
    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account).mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(
                rewards[account]
            );
    }

    /// @notice Pays earned reward to the user
    function getReward() nonReentrant external updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /// @notice Notifies contract about the reward amount
    /// @param reward reward amount
    function notifyRewardAmount(uint256 reward) external override onlyRewardDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }
}
