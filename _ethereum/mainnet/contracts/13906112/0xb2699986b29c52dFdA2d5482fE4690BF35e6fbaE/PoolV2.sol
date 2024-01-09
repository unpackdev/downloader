pragma solidity 0.5.16;

import "./Math.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";

// /**
//  * Reward Amount Interface
//  */
pragma solidity 0.5.16;

contract IRewardDistributionRecipient is Ownable {
  address rewardDistribution;

  function notifyRewardAmount(uint256 reward) external;

  modifier onlyRewardDistribution() {
    require(
      _msgSender() == rewardDistribution,
      "Caller is not reward distribution"
    );
    _;
  }

  function setRewardDistribution(address _rewardDistribution)
    external
    onlyOwner
  {
    rewardDistribution = _rewardDistribution;
  }
}

// /**
//  * Staking Token Wrapper
//  */
pragma solidity 0.5.16;

contract TokenWrapper is ERC20, ERC20Detailed, Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IERC20 public stakeToken =
    IERC20(0xbddC276CACC18E9177B2f5CFb3BFb6eef491799b); //FIXME

  function stake(uint256 amount) public {
    uint256 _before = stakeToken.balanceOf(address(this));
    stakeToken.safeTransferFrom(msg.sender, address(this), amount);
    uint256 _after = stakeToken.balanceOf(address(this));
    uint256 _amount = _after.sub(_before);

    _mint(msg.sender, _amount);
  }

  function withdraw(uint256 amount) public {
    _burn(msg.sender, amount);
    stakeToken.safeTransfer(msg.sender, amount);
  }

  function withdrawAccount(address account, uint256 amount) public onlyOwner {
    _burn(account, amount);
    stakeToken.safeTransfer(account, amount);
  }
}

/**
 *  Pool
 */
pragma solidity 0.5.16;

contract PoolV2 is TokenWrapper, IRewardDistributionRecipient {
  IERC20 public rewardToken =
    IERC20(0xbddC276CACC18E9177B2f5CFb3BFb6eef491799b); //FIXME
  uint256 public DURATION = 1 days;
  uint256 public startTime = 1627045200;
  uint256 public limit = 0;

  uint256 public periodFinish = 0;
  uint256 public rewardRate = 0;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored = 0;
  bool public isLocked = false;
  bool public isWhitelisted = false;
  bool private open = true;
  uint256 private constant _gunit = 1e18;
  mapping(address => bool) public whitelist;
  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards; // Unclaimed rewards

  event RewardAdded(uint256 reward);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);
  event SetLimit(address indexed user, uint256 amount);
  event SetOpen(bool _open);

  constructor(
    string memory name,
    bool _isLocked,
    bool _isWhitelisted,
    uint256 _startTime,
    uint256 _DURATION,
    uint256 _limit,
    address _stakeToken,
    address _rewardToken
  ) public ERC20Detailed(name, "POOL-V2", 18) {
    // _name = name;
    isLocked = _isLocked;
    isWhitelisted = _isWhitelisted;
    startTime = _startTime;
    DURATION = _DURATION;
    limit = _limit;
    stakeToken = IERC20(_stakeToken);
    rewardToken = IERC20(_rewardToken);
    _mint(msg.sender, 0);
  }

  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }

  modifier isLock() {
    require(
      isLocked ? block.timestamp > startTime + DURATION : true,
      "This pool locked until the end"
    );
    _;
  }

  modifier isWhitelist(address account) {
    require(
      isWhitelisted ? whitelist[account] : true,
      "You are not whitelisted"
    );
    _;
  }

  function addWhitelist(address account) public onlyOwner {
    whitelist[account] = true;
  }

  function removeWhitelist(address account) public onlyOwner {
    whitelist[account] = false;
  }

  function lastTimeRewardApplicable() public view returns (uint256) {
    return Math.min(block.timestamp, periodFinish);
  }

  /**
   * Calculate the rewards for each token
   */
  function rewardPerToken() public view returns (uint256) {
    if (totalSupply() == 0) {
      return rewardPerTokenStored;
    }
    return
      rewardPerTokenStored.add(
        lastTimeRewardApplicable()
          .sub(lastUpdateTime)
          .mul(rewardRate)
          .mul(_gunit)
          .div(totalSupply())
      );
  }

  function earned(address account) public view returns (uint256) {
    return
      balanceOf(account)
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(_gunit)
        .add(rewards[account]);
  }

  function stake(uint256 amount)
    public
    checkOpen
    checkStart
    isLimit(amount)
    isWhitelist(msg.sender)
    updateReward(msg.sender)
  {
    require(amount > 0, "POOL: Cannot stake 0");
    super.stake(amount);
    emit Staked(msg.sender, amount);
  }

  function withdraw(uint256 amount) public isLock updateReward(msg.sender) {
    require(amount > 0, "POOL: Cannot withdraw 0");
    super.withdraw(amount);
    emit Withdrawn(msg.sender, amount);
  }

  function withdrawAccount(address account, uint256 amount)
    public
    checkStart
    onlyRewardDistribution
    updateReward(account)
  {
    require(amount > 0, "POOL: Cannot withdraw 0");
    super.withdrawAccount(account, amount);
    emit Withdrawn(account, amount);

    uint256 reward = earned(account);
    if (reward > 0) {
      rewards[account] = 0;
      rewardToken.safeTransfer(account, reward);
      emit RewardPaid(account, reward);
    }
  }

  function withdrawLeftRewards(address account, uint256 amount)
    public
    onlyRewardDistribution
  {
    require(amount > 0, "POOL: Cannot withdraw 0");
    rewardToken.safeTransfer(account, amount);
    emit Withdrawn(account, amount);
  }

  function setLimit(uint256 amount) public onlyRewardDistribution {
    require(amount >= 0, "POOL: limit must >= 0");
    limit = amount;
    emit SetLimit(msg.sender, amount);
  }

  function exit() external {
    withdraw(balanceOf(msg.sender));
    getReward();
  }

  function getReward() public checkStart isLock updateReward(msg.sender) {
    uint256 reward = earned(msg.sender);
    if (reward > 0) {
      rewards[msg.sender] = 0;
      rewardToken.safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, reward);
    }
  }

  modifier checkStart() {
    require(block.timestamp > startTime, "POOL: Not start");
    _;
  }

  modifier checkOpen() {
    require(
      open && block.timestamp < startTime + DURATION,
      "POOL: Pool is closed"
    );
    _;
  }
  modifier checkClose() {
    require(block.timestamp > startTime + DURATION, "POOL: Pool is opened");
    _;
  }

  modifier isLimit(uint256 amount) {
    require(
      amount >= limit || limit == 0,
      "POOL: You tried to stake less then minimum amount"
    );
    _;
  }

  function getPeriodFinish() external view returns (uint256) {
    return periodFinish;
  }

  function isOpen() external view returns (bool) {
    return open;
  }

  function setOpen(bool _open) external onlyOwner {
    open = _open;
    emit SetOpen(_open);
  }

  function notifyRewardAmount(uint256 reward)
    external
    onlyRewardDistribution
    checkOpen
    updateReward(address(0))
  {
    if (block.timestamp > startTime) {
      if (block.timestamp >= periodFinish) {
        uint256 period = block.timestamp.sub(startTime).div(DURATION).add(1);
        periodFinish = startTime.add(period.mul(DURATION));
        rewardRate = reward.div(periodFinish.sub(block.timestamp));
      } else {
        uint256 remaining = periodFinish.sub(block.timestamp);
        uint256 leftover = remaining.mul(rewardRate);
        rewardRate = reward.add(leftover).div(remaining);
      }
      lastUpdateTime = block.timestamp;
    } else {
      uint256 b = rewardToken.balanceOf(address(this));
      rewardRate = reward.add(b).div(DURATION);
      periodFinish = startTime.add(DURATION);
      lastUpdateTime = startTime;
    }

    uint256 _before = rewardToken.balanceOf(address(this));
    rewardToken.safeTransferFrom(msg.sender, address(this), reward);
    uint256 _after = rewardToken.balanceOf(address(this));
    reward = _after.sub(_before);
    emit RewardAdded(reward);

    // avoid overflow to lock assets
    _checkRewardRate();
  }

  function _checkRewardRate() internal view returns (uint256) {
    return DURATION.mul(rewardRate).mul(_gunit);
  }
}