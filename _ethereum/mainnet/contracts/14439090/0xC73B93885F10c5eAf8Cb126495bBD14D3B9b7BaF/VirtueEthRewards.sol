// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./VirtueStaking.sol";
import "./IRewards.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

/**
  @notice VirtueEthRewards implements the IRewards interface and is meant to be added as an extra
    reward to the VirtueStaking contract through its addExtraReward function. It streams rewards
    of ETH to VIRTUE stakers at a constant rate over a defined period of time, with each user's
    share of the rewards doled out proportionally to the amount of VIRTUE they have staked.
*/
contract VirtueEthRewards is IRewards, ReentrancyGuard, Ownable {
  // stakingToken references the ERC20 token that is staked to claim rewards from this contract.
  // Should be VIRTUE for this particular contract.
  IERC20 public immutable stakingToken;

  // virtueStakingContract references the base VirtueStaking contract that this rewards contract
  // is being added to. VirtueStaking should be calling the stake/reward functions on this contract,
  // rather than users calling this contract's functions directly.
  VirtueStaking public immutable virtueStakingContract;

  // rewardsPeriodFinish holds the UNIX timestamp for when the rewards are scheduled to finish
  // being distributed.
  uint256 public rewardsPeriodFinish = 0;

  // rewardsDuration stores, in seconds, how long the rewards period should last for. Default is
  // 15 days = 15 * 24 * 60 * 60 = 1296000.
  uint256 public rewardsDuration = 15 days;

  // rewardsRefreshWindow stores the amount of time before the end of the rewards duration where
  // addReward can be called again to refresh the rewards period.
  uint256 public rewardsRefreshWindow = 1 days;

  // rewardRate stores the total amount of ETH that is distributed across all VIRTUE
  // stakers per second.
  uint256 public rewardRate;

  // rewardPerTokenStored stores the last recorded amount of ETH that is eligible to be
  // claimed per token of staked VIRTUE.
  uint256 public rewardPerTokenStored;

  // lastUpdateTime stores the last time the rewardPerTokenStored was updated.
  uint256 public lastUpdateTime;

  // userRewardPerTokenPaid stores, per user, how much ETH the user is no longer eligible to claim
  // per staked VIRTUE token.
  mapping(address => uint256) public userRewardPerTokenPaid;

  // rewards stores the amount of ETH that a user is eligible to claim since the last time
  // updateReward was called for that user.
  mapping(address => uint256) public rewards;

  // DECIMAL_PRECISION is used as a multiplier on the rewardPerTokenStored since the ratio cannot
  // always be accurately represented as a whole integer.
  uint constant DECIMAL_PRECISION = 10**18;

  // rewardsCollectorAddress stores the address of the RewardsCollector contract that this contract
  // expects to receive rewards from.
  address public rewardsCollectorAddress;

  constructor(address _stakingTokenAddress, address payable _virtueStakingAddress, address _rewardsCollectorAddress) {
    stakingToken = IERC20(_stakingTokenAddress);
    virtueStakingContract = VirtueStaking(_virtueStakingAddress);
    rewardsCollectorAddress = _rewardsCollectorAddress;
  }

  /**
    @notice totalStaked returns the total amount of VIRTUE token that is staked in the VirtueStaking
      contract.
  */
  function totalStaked() public view returns (uint256) {
    return stakingToken.balanceOf(address(virtueStakingContract));
  }

  /**
    @notice userStaked returns the amount of VIRTUE token that a particular user has staked in the
      VirtueStaking contract.
    @param _account The user to get VIRTUE stake for.
  */
  function userStaked(address _account) public view returns (uint256) {
    return virtueStakingContract.getUserVirtueStake(_account);
  }

  /**
    @notice lastTimeRewardApplicable returns the most recent timestamp where the rewards period was
      still active (which is the current timestamp is the rewards period is currently active).
  */
  function lastTimeRewardApplicable() public view returns (uint256) {
    return block.timestamp < rewardsPeriodFinish ? block.timestamp : rewardsPeriodFinish;
  }

  /**
    @notice rewardPerToken returns the amount of ETH that is currently eligible to be claimed per
      staked VIRTUE token.
  */
  function rewardPerToken() public view returns (uint256) {
    if (totalStaked() == 0) {
      return rewardPerTokenStored;
    }
    return rewardPerTokenStored + (lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * DECIMAL_PRECISION / totalStaked();
  }

  /**
    @notice earned returns the amount that a specified user is currently eligible to claim.
    @param _account The user to view earned rewards for.
  */
  function earned(address _account) public view returns (uint256) {
    return rewards[_account] + userStaked(_account) * (rewardPerToken() - userRewardPerTokenPaid[_account]) / DECIMAL_PRECISION;
  }

  /**
    @notice getRewardForDuration returns the total amount of rewards that were set to be distributed
      over the most recent rewards period.
  */
  function getRewardForDuration() external view returns (uint256) {
    return rewardRate * rewardsDuration;
  }

  /**
    @notice increaseStake is called for a user when their VIRTUE stake in the VirtueStaking contract
      is increased.
    @param _for The address of the user whose VIRTUE stake has been increased.
    @param _amount The amount of VIRTUE staked.
  */
  function increaseStake(address _for, uint256 _amount) external onlyStakingContract updateReward(_for) {
    // This function actually does nothing other than call updateReward since staking balances are
    // stored in the VirtueStaking contract.
  }

  /**
    @notice decreaseStake is called for a user when their VIRTUE stake in the VirtueStaking contract
      is decreased.
    @param _for The address of the user whose VIRTUE stake has been decreased.
    @param _amount The amount of VIRTUE stake withdrawn.
  */
  function decreaseStake(address _for, uint256 _amount) external onlyStakingContract updateReward(_for) {
    // This function actually does nothing other than call updateReward since staking balances are
    // stored in the VirtueStaking contract.
  }

  /**
    @notice claimRewards takes the amount of ETH that a user is eligible to claim and transfers the
      ETH to their address.
    @param _for The address to claim rewards for.
  */
  function claimRewards(address _for) external onlyStakingContract updateReward(_for) {
    uint256 reward = rewards[_for];
    if (reward > 0) {
      rewards[_for] = 0;
      Address.sendValue(payable(_for), reward);
    }
  }

  /**
    @notice addReward allocates a certain amount of ETH to be distributed amongst
      VIRTUE stakers over the current rewardsDuration. If a previous reward is still actively being
      distributed, the remaining undistributed amount is added to _rewardAmount and the duration
      of the rewards period is overwritten to start at the current timestamp.
  */
  function addReward() external payable onlyRewardsCollector updateReward(address(0)) {
    if (block.timestamp < rewardsPeriodFinish) {
      require(rewardsPeriodFinish - block.timestamp <= rewardsRefreshWindow, "Too early to call addReward during current rewards period");
    }

    uint rewardAmount = msg.value;
    if (block.timestamp >= rewardsPeriodFinish) {
      rewardRate = rewardAmount / rewardsDuration;
    } else {
      uint256 remainingTime = rewardsPeriodFinish - block.timestamp;
      uint256 leftoverReward = remainingTime * rewardRate;
      uint256 newRewardRate = (rewardAmount + leftoverReward) / rewardsDuration;
      rewardRate = newRewardRate;
    }

    // Ensure the provided reward amount is not more than the balance in the contract.
    // This keeps the reward rate in the right range, preventing overflows due to
    // very high values of rewardRate in the earned and rewardsPerToken functions;
    // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
    uint balance = address(this).balance;
    require(rewardRate <= balance / rewardsDuration, "Provided reward too high");

    lastUpdateTime = block.timestamp;
    rewardsPeriodFinish = block.timestamp + rewardsDuration;
  }

  /**
    @notice setRewardsDuration is used to update the duration of the reward period.
    @param _rewardsDuration The length of the new rewards period, in seconds.
  */
  function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
    require(block.timestamp > rewardsPeriodFinish, "Previous rewards period must be completed before updating duration");
    rewardsDuration = _rewardsDuration;
  }

  function setRewardsRefreshWindow(uint256 _rewardsRefreshWindow) external onlyOwner {
    rewardsRefreshWindow = _rewardsRefreshWindow;
  }

  function setRewardsCollectorAddress(address _rewardsCollectorAddress) external onlyOwner {
    rewardsCollectorAddress = _rewardsCollectorAddress;
  }

  modifier onlyStakingContract {
    require(msg.sender == address(virtueStakingContract), "Can only be called by the operating VirtueStaking contract");
    _;
  }

  modifier onlyRewardsCollector {
    require(msg.sender == rewardsCollectorAddress, "Can only be called by the RewardsCollector contract");
    _;
  }

  /**
    @notice updateReward is called to update a user's rewards whenever their stake is updated or
      they want to claim their existing rewards.
    @param _for The address to update rewards for.
  */
  modifier updateReward(address _for) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (_for != address(0)) {
      rewards[_for] = earned(_for);
      userRewardPerTokenPaid[_for] = rewardPerTokenStored;
    }
    _;
  }
}
