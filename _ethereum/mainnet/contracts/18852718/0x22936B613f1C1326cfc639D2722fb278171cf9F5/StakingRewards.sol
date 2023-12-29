// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

import "./IERC20Burnable.sol";

contract StakingRewards is Ownable, Pausable, ReentrancyGuard {
  /* ========== STATE VARIABLES ========== */

  IERC20Burnable public stakingToken;

  IERC20Burnable public rewardsToken;

  uint256 public periodFinish = 0;

  uint256 public rewardRate = 0;

  uint256 public rewardsDuration = 0;

  uint256 public lastUpdateTime;

  uint256 public rewardPerTokenStored;

  mapping(address => uint256) public userRewardPerTokenPaid;

  mapping(address => uint256) public rewards;

  uint256 private _totalSupply;

  mapping(address => uint256) private _balances;

  /* ========== CONSTRUCTOR ========== */

  constructor(address _owner, address _stakingToken, address _rewardsToken, uint256 _rewardsDuration) Ownable(_owner) {
    stakingToken = IERC20Burnable(_stakingToken);
    rewardsToken = IERC20Burnable(_rewardsToken);
    rewardsDuration = _rewardsDuration;
  }

  /* ========== VIEWS ========== */

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  function lastTimeRewardApplicable() public view returns (uint256) {
    return getBlockTimestamp() < periodFinish ? getBlockTimestamp() : periodFinish;
  }

  function rewardPerToken() public view returns (uint256) {
    if (_totalSupply == 0) {
      return rewardPerTokenStored;
    }
    return rewardPerTokenStored + (((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / _totalSupply);
  }

  function earned(address account) public view returns (uint256) {
    return ((_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) + rewards[account];
  }

  function getBlockTimestamp() public view virtual returns (uint256) {
    return block.timestamp;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function stake(uint256 amount) external nonReentrant whenNotPaused updateReward(msg.sender) {
    require(amount > 0, 'Cannot stake 0');
    _totalSupply += amount;
    _balances[msg.sender] += amount;
    stakingToken.transferFrom(msg.sender, address(this), amount);
    emit Staked(msg.sender, amount);
  }

  function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
    require(amount > 0, 'Cannot withdraw 0');
    _totalSupply -= amount;
    _balances[msg.sender] -= amount;
    stakingToken.transfer(msg.sender, amount);
    emit Withdrawn(msg.sender, amount);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /**
   * @notice Burn unassigned rewards token
   */
  function burnUnassignedRewards() external onlyOwner {
    uint256 balance = rewardsToken.balanceOf(address(this));
    if (balance > 0) {
      rewardsToken.burn(balance);
    }
  }

  function getRewardFor(address account) external onlyOwner nonReentrant updateReward(account) {
    require(account != address(0), 'invalid account');

    uint256 reward = rewards[account];
    if (reward > 0) {
      rewards[account] = 0;
      // burn rewards token, no need to transfer, rewards distribution will be done on BASE network by the owner
      rewardsToken.burn(reward);
      emit RewardPaid(account, reward);
    }
  }

  function notifyRewardAmount(uint256 reward) external onlyOwner updateReward(address(0)) {
    if (getBlockTimestamp() >= periodFinish) {
      rewardRate = reward / rewardsDuration;
    } else {
      uint256 remaining = periodFinish - getBlockTimestamp();
      uint256 leftover = remaining * rewardRate;
      rewardRate = (reward + leftover) / rewardsDuration;
    }

    lastUpdateTime = getBlockTimestamp();
    periodFinish = getBlockTimestamp() + rewardsDuration;
    rewardsToken.transferFrom(msg.sender, address(this), reward);
    emit RewardAdded(reward);
  }

  function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
    require(tokenAddress != address(stakingToken), 'Cannot withdraw the staking token');
    IERC20(tokenAddress).transfer(owner(), tokenAmount);
    emit Recovered(tokenAddress, tokenAmount);
  }

  function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
    require(
      getBlockTimestamp() > periodFinish,
      'Previous rewards period must be complete before changing the duration for the new period'
    );
    rewardsDuration = _rewardsDuration;
    emit RewardsDurationUpdated(rewardsDuration);
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  /* ========== MODIFIERS ========== */

  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }

  /* ========== EVENTS ========== */

  event RewardAdded(uint256 reward);

  event Staked(address indexed user, uint256 amount);

  event Withdrawn(address indexed user, uint256 amount);

  event RewardPaid(address indexed user, uint256 reward);

  event RewardsDurationUpdated(uint256 newDuration);

  event Recovered(address token, uint256 amount);
}
