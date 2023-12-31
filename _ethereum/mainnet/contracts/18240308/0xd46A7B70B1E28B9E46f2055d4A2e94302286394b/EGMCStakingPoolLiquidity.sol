// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

import "./IUniswapV2Router02.sol";
import "./IEGMC.sol";

contract EGMCStakingPoolLiquidity is Ownable, ReentrancyGuard, Pausable {
  using SafeMath for uint;
  using SafeERC20 for IERC20;

  struct User {
    uint balance;
    uint reward;
    uint depositTimestamp;
    uint claimTimestamp;
  }

  // STATE VARIABLES

  IEGMC public rewardToken;
  IERC20 public stakingToken;
  address public vault;
  address public manager;
  uint public aprRate;
  uint public lockPeriod = 1 weeks;
  uint public lastRewardTimestamp;
  bool public rewardsDisabled;

  address private immutable pair;
  address private immutable WETH;
  uint private _totalSupply;
  uint private _totalParticipants;

  mapping(address => User) private _users;

  // CONSTRUCTOR

  constructor (
    address _rewardToken,
    address _vault,
    uint _aprRate
  ) {
    rewardToken = IEGMC(_rewardToken);
    pair = rewardToken.uniswapV2Pair();
    stakingToken = IERC20(pair);
    WETH = rewardToken.WETH();
    vault = _vault;
    aprRate = _aprRate;
  }

  // VIEWS

  function totalSupply() external view returns (uint) {
    return _totalSupply;
  }

  function totalParticipants() external view returns (uint) {
    return _totalParticipants;
  }

  function balanceOf(address account) external view returns (uint) {
    return _users[account].balance;
  }

  function balanceOfInTokens(address account) public view returns (uint) {
    uint tokenBalance = rewardToken.balanceOf(pair);
    uint lpBalance = IERC20(pair).totalSupply();
    uint tokensPerLp = tokenBalance.mul(1e18).div(lpBalance);
    return tokensPerLp
        .mul(2)
        .mul(_users[account].balance)
        .div(1e18);
  }

  function earned(address account) public view returns (uint) {
    return 
      _users[account].reward
        .add(_getUnclaimedReward(account));
  }

  function unlockedAt(address account) public view returns (uint) {
    return 
      _users[account].depositTimestamp
        .add(lockPeriod);
  }

  function getRewardRate(address account) public view returns (uint) {
    return 
      balanceOfInTokens(account)
        .mul(aprRate)
        .div(1000)
        .div(365 days);
  }

  function min(uint a, uint b) public pure returns (uint) {
    return a < b ? a : b;
  }

  // PUBLIC FUNCTIONS

  function stake(address account, uint amount, bool isCompound)
    external
    nonReentrant
    whenNotPaused
    onlyManager
  {
    require(amount > 0, "Cannot stake 0");

    uint balBefore = stakingToken.balanceOf(address(this));
    if (isCompound) stakingToken.safeTransferFrom(_msgSender(), address(this), amount);
    else stakingToken.safeTransferFrom(account, address(this), amount);
    uint balAfter = stakingToken.balanceOf(address(this));
    uint actualReceived = balAfter.sub(balBefore);

    _claimPendingReward(account);
    _totalSupply = _totalSupply.add(actualReceived);
    if (_users[account].balance == 0) {
      _totalParticipants = _totalParticipants.add(1);
    }
    _users[account].balance = _users[account].balance.add(actualReceived);
    _users[account].depositTimestamp = block.timestamp;
    
    emit Staked(account, actualReceived);
  }

  function withdraw(address account, uint amount)
    public
    nonReentrant
    onlyManager
  {
    require(amount > 0, "Cannot withdraw 0");
    require(block.timestamp >= unlockedAt(account), "Cannot withdraw yet");

    _claimPendingReward(account);
    _totalSupply = _totalSupply.sub(amount);
    _users[account].balance = _users[account].balance.sub(amount);
    if (_users[account].balance == 0) {
      _totalParticipants = _totalParticipants.sub(1);
    }
    stakingToken.safeTransfer(account, amount);

    emit Withdrawn(account, amount);
  }

  function claim(address account, bool compound) 
    public 
    nonReentrant
    onlyManager
  {
    uint reward = earned(account);
    if (reward > 0) {
      _users[account].reward = 0;
      _users[account].claimTimestamp = block.timestamp;

      if (compound) IERC20(rewardToken).safeTransferFrom(vault, _msgSender(), reward);
      else IERC20(rewardToken).safeTransferFrom(vault, account, reward);
      emit RewardPaid(account, reward);
    }
  }

  // INTERNAL FUNCTIONS

  function _claimPendingReward(address account) internal {
    _users[account].reward = _users[account].reward.add(_getUnclaimedReward(account));
    _users[account].claimTimestamp = block.timestamp;
  }

  function _getUnclaimedReward(address account) internal view returns (uint) {
    uint lastApplicableTimestamp = block.timestamp;
    if (lastRewardTimestamp != 0 && block.timestamp > lastRewardTimestamp)
      lastApplicableTimestamp = lastRewardTimestamp;

    if (_users[account].claimTimestamp > lastApplicableTimestamp) {
      return 0;
    } else {
      return
        getRewardRate(account)
          .mul(lastApplicableTimestamp.sub(_users[account].claimTimestamp));
    }
  }

  // RESTRICTED FUNCTIONS

  function recoverTokens(address tokenAddress, uint tokenAmount)
    external
    onlyOwner
  {
    // Cannot recover the staking token or the reward token
    require(
        tokenAddress != address(stakingToken) &&
            tokenAddress != address(rewardToken),
        "Cannot withdraw the staking or reward tokens"
    );
    IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
    emit Recovered(tokenAddress, tokenAmount);
  }

  function enableDeposits()
    external
    onlyOwner
  {
    _unpause();
  }

  function disableDeposits()
    external
    onlyOwner
  {
    _pause();
  }

  function disableRewards()
    external
    onlyOwner
  {
    require(!rewardsDisabled, "Rewards are already disabled");
    rewardsDisabled = true;
    lastRewardTimestamp = block.timestamp;
  }

  function setVault(address _vault)
    external
    onlyOwner
  {
    require(_vault != address(0), "Vault can not be null address");
    vault = _vault;
  }

  function setManager(address _manager)
    external
    onlyOwner
  {
    require(_manager != address(0), "Manager can not be null address");
    manager = _manager;
  }

  function setAprRate(uint _aprRate)
    external
    onlyOwner
  {
    require(_aprRate > 0, "APR rate must be more than zero");
    aprRate = _aprRate;
  }

  function setLockPeriod(uint _lockPeriod)
    external
    onlyOwner
  {
    require(_lockPeriod <= 30 days, "Lock period can not be more than 30 days");
    lockPeriod = _lockPeriod;
  }

  // MODIFIERS

  modifier onlyManager()
  {
    require(
      _msgSender() == manager,
      "Only the manager can call this function"
    );

    _;
  }

  // EVENTS

  event Staked(address indexed user, uint amount);
  event Withdrawn(address indexed user, uint amount);
  event RewardPaid(address indexed user, uint reward);
  event Recovered(address token, uint amount);
}