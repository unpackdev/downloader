// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


import {MathUpgradeable as Math} from "MathUpgradeable.sol";
import {OwnableUpgradeable as Ownable} from "OwnableUpgradeable.sol";
import {IERC20Upgradeable as IERC20} from "IERC20Upgradeable.sol";
import {PausableUpgradeable as Pausable} from "PausableUpgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "SafeERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable as ReentrancyGuard} from "ReentrancyGuardUpgradeable.sol";

contract MultiRewards is Ownable, ReentrancyGuard, Pausable {
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

  struct Reward {
    bool shouldTransfer;
    address rewardsDistributor;
    uint256 rewardsDuration;
    uint256 periodFinish;
    uint256 rewardRate;
    uint256 lastUpdateTime;
    uint256 rewardPerTokenStored;
  }
  IERC20 public stakingToken;
  mapping(address => Reward) public rewardData;
  address[] public rewardTokens;

  // user -> reward token -> amount
  mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
  mapping(address => mapping(address => uint256)) public rewards;

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;

  /* ========== INITIALIZE ========== */

  function initialize(address _owner, address _stakingToken) public initializer {
    stakingToken = IERC20(_stakingToken);

    // Init base contracts.

    __Ownable_init();
    __Pausable_init();
    __ReentrancyGuard_init();

    // Transfer ownership.
    transferOwnership(_owner);
  }

  /* ========== ADD NEW REWARD TOKEN ========== */
  function addReward(
    address _rewardsToken,
    address _rewardsDistributor,
    uint256 _rewardsDuration,
    bool _shouldTransfer // wheter to transfer the rewards from the rewards distributor upon notifyReward call or not
  ) public onlyOwner {
    require(rewardData[_rewardsToken].rewardsDuration == 0);
    rewardTokens.push(_rewardsToken);
    rewardData[_rewardsToken].rewardsDistributor = _rewardsDistributor;
    rewardData[_rewardsToken].rewardsDuration = _rewardsDuration;
    rewardData[_rewardsToken].shouldTransfer = _shouldTransfer;
  }

  /* ========== VIEWS ========== */

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  function lastTimeRewardApplicable(address _rewardsToken) public view returns (uint256) {
    return Math.min(block.timestamp, rewardData[_rewardsToken].periodFinish);
  }

  function rewardPerToken(address _rewardsToken) public view returns (uint256) {
    if (_totalSupply == 0) {
      return rewardData[_rewardsToken].rewardPerTokenStored;
    }
    return rewardData[_rewardsToken].rewardPerTokenStored + (
      (lastTimeRewardApplicable(_rewardsToken) - rewardData[_rewardsToken].lastUpdateTime) * rewardData[_rewardsToken].rewardRate * 1e18 / _totalSupply
    );
  }

  function earned(address account, address _rewardsToken) public view returns (uint256) {
    return (_balances[account] * (rewardPerToken(_rewardsToken) - userRewardPerTokenPaid[account][_rewardsToken]) / 1e18 ) + rewards[account][_rewardsToken];
  }

  function getRewardForDuration(address _rewardsToken) external view returns (uint256) {
    return rewardData[_rewardsToken].rewardRate * rewardData[_rewardsToken].rewardsDuration;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function setRewardsDistributor(address _rewardsToken, address _rewardsDistributor) external onlyOwner {
    rewardData[_rewardsToken].rewardsDistributor = _rewardsDistributor;
  }

  function stake(uint256 amount) external nonReentrant whenNotPaused updateReward(msg.sender) {
    require(amount > 0, "Cannot stake 0");
    _totalSupply += amount;
    _balances[msg.sender] += amount;
    stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    emit Staked(msg.sender, amount);
  }

  function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
    require(amount > 0, "Cannot withdraw 0");
    _totalSupply -= amount;
    _balances[msg.sender] -= amount;
    stakingToken.safeTransfer(msg.sender, amount);
    emit Withdrawn(msg.sender, amount);
  }

  function getReward() public nonReentrant updateReward(msg.sender) {
    address[] memory _rewardsTokenArr = rewardTokens;

    for (uint256 i; i < _rewardsTokenArr.length; i++) {
      address _rewardsToken = _rewardsTokenArr[i];
      uint256 reward = rewards[msg.sender][_rewardsToken];
      if (reward > 0) {
        rewards[msg.sender][_rewardsToken] = 0;
        IERC20(_rewardsToken).safeTransfer(msg.sender, reward);
        emit RewardPaid(msg.sender, _rewardsToken, reward);
      }
    }
  }

  function exit() external {
    withdraw(_balances[msg.sender]);
    getReward();
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function depositReward(address _rewardsToken, uint256 reward) external updateReward(address(0)) {
    require(rewardData[_rewardsToken].rewardsDistributor == msg.sender);
    if (rewardData[_rewardsToken].shouldTransfer) {
      IERC20(_rewardsToken).safeTransferFrom(msg.sender, address(this), reward);
    }

    if (block.timestamp >= rewardData[_rewardsToken].periodFinish) {
      rewardData[_rewardsToken].rewardRate = reward / rewardData[_rewardsToken].rewardsDuration;
    } else {
      uint256 remaining = rewardData[_rewardsToken].periodFinish - block.timestamp;
      uint256 leftover = remaining * rewardData[_rewardsToken].rewardRate;
      rewardData[_rewardsToken].rewardRate = (reward + leftover) / rewardData[_rewardsToken].rewardsDuration;
    }

    rewardData[_rewardsToken].lastUpdateTime = block.timestamp;
    rewardData[_rewardsToken].periodFinish = block.timestamp + rewardData[_rewardsToken].rewardsDuration;
    emit RewardAdded(reward);
  }

  // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
    require(tokenAddress != address(stakingToken), "Cannot withdraw staking token");
    require(rewardData[tokenAddress].lastUpdateTime == 0, "Cannot withdraw reward token");
    IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
    emit Recovered(tokenAddress, tokenAmount);
  }

  function setRewardsDuration(address _rewardsToken, uint256 _rewardsDuration) external {
    require(
      block.timestamp > rewardData[_rewardsToken].periodFinish,
      "Reward period still active"
    );
    require(rewardData[_rewardsToken].rewardsDistributor == msg.sender);
    require(_rewardsDuration > 0, "Reward duration must be non-zero");
    rewardData[_rewardsToken].rewardsDuration = _rewardsDuration;
    emit RewardsDurationUpdated(_rewardsToken, rewardData[_rewardsToken].rewardsDuration);
  }

  function setShouldTransferRewards(address _rewardsToken, bool _shouldTransfer) external onlyOwner {
    rewardData[_rewardsToken].shouldTransfer = _shouldTransfer;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  /* ========== MODIFIERS ========== */

  modifier updateReward(address account) {
    address[] memory _rewardsToken = rewardTokens;

    for (uint256 i; i < _rewardsToken.length; i++) {
      address token = _rewardsToken[i];
      rewardData[token].rewardPerTokenStored = rewardPerToken(token);
      rewardData[token].lastUpdateTime = lastTimeRewardApplicable(token);
      if (account != address(0)) {
        rewards[account][token] = earned(account, token);
        userRewardPerTokenPaid[account][token] = rewardData[token].rewardPerTokenStored;
      }
    }
    _;
  }

  /* ========== EVENTS ========== */

  event RewardAdded(uint256 reward);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, address indexed rewardsToken, uint256 reward);
  event RewardsDurationUpdated(address token, uint256 newDuration);
  event Recovered(address token, uint256 amount);
}