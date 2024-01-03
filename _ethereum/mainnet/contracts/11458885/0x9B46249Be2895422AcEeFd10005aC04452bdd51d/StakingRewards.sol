// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/* ==========  External Libraries  ========== */
import "./Math.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

/* ==========  External Inheritance  ========== */
import "./ReentrancyGuard.sol";

/* ==========  Internal Inheritance  ========== */
import "./RewardsDistributionRecipient.sol";
import "./IStakingRewards.sol";


contract StakingRewards is
  IStakingRewards,
  RewardsDistributionRecipient,
  ReentrancyGuard
{
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

/* ==========  Constants  ========== */

  uint256 public override rewardsDuration = 60 days;

/* ==========  Immutables  ========== */

  IERC20 public override immutable rewardsToken;

/* ========== Events ========== */

  event RewardAdded(uint256 reward);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);
  event RewardsDurationUpdated(uint256 newDuration);
  event Recovered(address token, uint256 amount);

/* ========== Modifiers ========== */

  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }

/* ==========  State Variables  ========== */

  IERC20 public override stakingToken;
  uint256 public override periodFinish = 0;
  uint256 public override rewardRate = 0;
  uint256 public override lastUpdateTime;
  uint256 public override rewardPerTokenStored;

  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;

/* ==========  Constructor & Initializer  ========== */

  constructor(
    address rewardsDistribution_,
    address rewardsToken_
  ) public RewardsDistributionRecipient(rewardsDistribution_) {
    rewardsToken = IERC20(rewardsToken_);
  }

  function initialize(address stakingToken_, uint256 rewardsDuration_) external override {
    require(address(stakingToken) == address(0), "Already initialized");
    require(address(stakingToken_) != address(0), "Can not set null staking token");
    require(rewardsDuration_ > 0, "Can not set null rewards duration");

    stakingToken = IERC20(stakingToken_);
    rewardsDuration = rewardsDuration_;
  }

/* ==========  Mutative Functions  ========== */

  function stake(uint256 amount)
    external
    override
    nonReentrant
    updateReward(msg.sender)
  {
    require(amount > 0, "Cannot stake 0");
    _totalSupply = _totalSupply.add(amount);
    _balances[msg.sender] = _balances[msg.sender].add(amount);
    stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    emit Staked(msg.sender, amount);
  }

  function withdraw(uint256 amount)
    public
    override
    nonReentrant
    updateReward(msg.sender)
  {
    require(amount > 0, "Cannot withdraw 0");
    _totalSupply = _totalSupply.sub(amount);
    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    stakingToken.safeTransfer(msg.sender, amount);
    emit Withdrawn(msg.sender, amount);
  }

  function getReward()
    public
    override
    nonReentrant
    updateReward(msg.sender)
  {
    uint256 reward = rewards[msg.sender];
    if (reward > 0) {
      rewards[msg.sender] = 0;
      rewardsToken.safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, reward);
    }
  }

  function exit() external override {
    withdraw(_balances[msg.sender]);
    getReward();
  }

/* ========== Restricted Functions ========== */

  function notifyRewardAmount(uint256 reward)
    external
    override(IStakingRewards, RewardsDistributionRecipient)
    onlyRewardsDistribution
    updateReward(address(0))
  {
    if (block.timestamp >= periodFinish) {
      rewardRate = reward.div(rewardsDuration);
    } else {
      uint256 remaining = periodFinish.sub(block.timestamp);
      uint256 leftover = remaining.mul(rewardRate);
      rewardRate = reward.add(leftover).div(rewardsDuration);
    }

    // Ensure the provided reward amount is not more than the balance in the contract.
    // This keeps the reward rate in the right range, preventing overflows due to
    // very high values of rewardRate in the earned and rewardsPerToken functions;
    // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
    uint256 balance = rewardsToken.balanceOf(address(this));
    require(
      rewardRate <= balance.div(rewardsDuration),
      "Provided reward too high"
    );

    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp.add(rewardsDuration);
    emit RewardAdded(reward);
  }

  // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
  function recoverERC20(address tokenAddress, address recipient) external override onlyRewardsDistribution {
    // Cannot recover the staking token or the rewards token
    require(
      tokenAddress != address(stakingToken) && tokenAddress != address(rewardsToken),
      "Cannot withdraw the staking or rewards tokens"
    );
    uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
    IERC20(tokenAddress).safeTransfer(recipient, balance);
    emit Recovered(tokenAddress, balance);
  }

  function setRewardsDuration(uint256 _rewardsDuration) external override onlyRewardsDistribution {
    require(
      block.timestamp > periodFinish,
      "Previous rewards period must be complete before changing the duration for the new period"
    );
    require(_rewardsDuration > 0, "Can not set null rewards duration.");
    rewardsDuration = _rewardsDuration;
    emit RewardsDurationUpdated(rewardsDuration);
  }

/* ==========  Views  ========== */

  function totalSupply() external override view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external override view returns (uint256) {
    return _balances[account];
  }

  function lastTimeRewardApplicable() public override view returns (uint256) {
    return Math.min(block.timestamp, periodFinish);
  }

  function rewardPerToken() public override view returns (uint256) {
    if (_totalSupply == 0) {
      return rewardPerTokenStored;
    }
    return
      rewardPerTokenStored.add(
        lastTimeRewardApplicable()
          .sub(lastUpdateTime)
          .mul(rewardRate)
          .mul(1e18)
          .div(_totalSupply)
      );
  }

  function earned(address account) public override view returns (uint256) {
    return _balances[account]
      .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
      .div(1e18)
      .add(rewards[account]);
  }

  function getRewardForDuration() external override view returns (uint256) {
    return rewardRate.mul(rewardsDuration);
  }
}
