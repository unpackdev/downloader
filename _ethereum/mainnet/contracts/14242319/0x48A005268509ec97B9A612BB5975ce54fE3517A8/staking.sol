// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;
import "./IERC20MetadataUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20.sol";

contract EmergencyWithdraw is OwnableUpgradeable {
  event Received(address sender, uint amount);

  /**
   * @dev allow contract to receive ethers
   */
  receive() external payable {
    emit Received(_msgSender(), msg.value);
  }

  /**
   * @dev get the eth balance on the contract
   * @return eth balance
   */
  function getEthBalance() external view returns (uint) {
    return address(this).balance;
  }

  /**
   * @dev withdraw eth balance
   */
  function emergencyWithdrawEthBalance(address _to, uint _amount) external onlyOwner {
    require(_to != address(0), "Invalid to");
    payable(_to).transfer(_amount);
  }

  /**
   * @dev get the token balance
   * @param _tokenAddress token address
   */
  function getTokenBalance(address _tokenAddress) external view returns (uint) {
    IERC20 erc20 = IERC20(_tokenAddress);
    return erc20.balanceOf(address(this));
  }

  /**
   * @dev withdraw token balance
   * @param _tokenAddress token address
   */
  function emergencyWithdrawTokenBalance(
    address _tokenAddress,
    address _to,
    uint _amount
  ) external onlyOwner {
    IERC20 erc20 = IERC20(_tokenAddress);
    erc20.transfer(_to, _amount);
  }
}

contract DSMath {
  function add(uint x, uint y) internal pure returns (uint z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
  }

  function sub(uint x, uint y) internal pure returns (uint z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
  }

  function min(uint x, uint y) internal pure returns (uint z) {
    return x <= y ? x : y;
  }

  function max(uint x, uint y) internal pure returns (uint z) {
    return x >= y ? x : y;
  }

  function imin(int x, int y) internal pure returns (int z) {
    return x <= y ? x : y;
  }

  function imax(int x, int y) internal pure returns (int z) {
    return x >= y ? x : y;
  }

  uint internal constant WAD = 10**18;
  uint internal constant RAY = 10**27;

  //rounds to zero if x*y < WAD / 2
  function wmul(uint x, uint y) internal pure returns (uint z) {
    z = add(mul(x, y), WAD / 2) / WAD;
  }

  //rounds to zero if x*y < WAD / 2
  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = add(mul(x, y), RAY / 2) / RAY;
  }

  //rounds to zero if x*y < WAD / 2
  function wdiv(uint x, uint y) internal pure returns (uint z) {
    z = add(mul(x, WAD), y / 2) / y;
  }

  //rounds to zero if x*y < RAY / 2
  function rdiv(uint x, uint y) internal pure returns (uint z) {
    z = add(mul(x, RAY), y / 2) / y;
  }

  // This famous algorithm is called "exponentiation by squaring"
  // and calculates x^n with x as fixed-point and n as regular unsigned.
  //
  // It's O(log n), instead of O(n) for naive repeated multiplication.
  //
  // These facts are why it works:
  //
  //  If n is even, then x^n = (x^2)^(n/2).
  //  If n is odd,  then x^n = x * x^(n-1),
  //   and applying the equation for even x gives
  //    x^n = x * (x^2)^((n-1) / 2).
  //
  //  Also, EVM division is flooring and
  //    floor[(n-1) / 2] = floor[n / 2].
  //
  function rpow(uint x, uint n) internal pure returns (uint z) {
    z = n % 2 != 0 ? x : RAY;

    for (n /= 2; n != 0; n /= 2) {
      x = rmul(x, x);

      if (n % 2 != 0) {
        z = rmul(z, x);
      }
    }
  }

  // MATH Exponentiation
  // x ^ n using base b
  // EX: rpow(1.1 ether, 30e6, 1 ether) = (1.1 ^ 30e6) ether
  function rpow(
    uint x,
    uint n,
    uint b
  ) internal pure returns (uint z) {
    // solhint-disable no-inline-assembly
    assembly {
      switch x
      case 0 {
        switch n
        case 0 {
          z := b
        }
        default {
          z := 0
        }
      }
      default {
        switch mod(n, 2)
        case 0 {
          z := b
        }
        default {
          z := x
        }
        let half := div(b, 2) // for rounding.
        for {
          n := div(n, 2)
        } n {
          n := div(n, 2)
        } {
          let xx := mul(x, x)
          if iszero(eq(div(xx, x), x)) {
            revert(0, 0)
          }
          let xxRound := add(xx, half)
          if lt(xxRound, xx) {
            revert(0, 0)
          }
          x := div(xxRound, b)
          if mod(n, 2) {
            let zx := mul(z, x)
            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
              revert(0, 0)
            }
            let zxRound := add(zx, half)
            if lt(zxRound, zx) {
              revert(0, 0)
            }
            z := div(zxRound, b)
          }
        }
      }
    }
  }
}

contract Staking is OwnableUpgradeable, ReentrancyGuardUpgradeable, EmergencyWithdraw, DSMath {
  using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

  struct UserInfo {
    address addr; // Address of user
    uint256 amount; // How many staked tokens the user has provided
    uint256 lastRewardTime; // Last reward time
    uint256 depositTime; // Last deposit time
    uint256 lockDuration; // Lock duration in seconds
    bool registered; // It will add user in address list on first deposit
  }

  struct UserLog {
    address addr; // Address of user
    uint256 amount1; // Raw amount of token
    uint256 amount2; // Amount after tax of token in Deposit case.
    uint256 amount3; // Pending reward
    bool isDeposit; // Deposit or withdraw
    uint256 logTime; // Log timestamp
  }

  // Percentage nominator: 1% = 100
  uint256 private constant _RATE_NOMINATOR = 10_000;
  // Total second in a year
  uint256 public constant SECONDS_YEAR = 365 days;

  // The reward token
  IERC20MetadataUpgradeable public rewardToken;
  // The staked token
  IERC20MetadataUpgradeable public stakedToken;

  // Info of each user that stakes tokens (stakedToken)
  mapping(address => UserInfo) public userInfo;
  // User list
  address[] public userList;
  // User logs
  UserLog[] private _userLogs;

  // Max reward tokens per pool
  uint256 public maxRewardPerPool;
  // Claimed reward tokens per pool
  uint256 public claimedRewardPerPool;
  // Max staked tokens per pool
  uint256 public maxStakedPerPool;
  // Whether a limit is set for users
  bool public hasUserLimit;
  // Max staked tokens per user (0 if none)
  uint256 public maxStakedPerUser;
  // Fixed APY, default is 100%
  uint256 public fixedAPY;
  // Pool mode: AUTO COMPOUND as default
  bool public isAutoCompound;

  // Current staked tokens per pool
  uint256 public currentStakedPerPool;
  // The Pool start time.
  uint256 public startTime;
  // The Pool end time.
  uint256 public endTime;
  // Freeze start time
  uint256 public freezeStartTime;
  // Freeze end time
  uint256 public freezeEndTime;
  // Minimum deposit amount
  uint256 public minDepositAmount;
  // Time for withdraw. Allow user can withdraw if block.timestamp >= withdrawTime
  uint256 public withdrawTime;
  // Withdraw mode
  // 0: Apply withdrawTime to both (stake + reward)
  // 1: Apply withdrawTime to stake
  // 2: Apply withdrawTime to reward
  uint256 public withdrawMode;
  // Global lock to user mode
  bool public enableLockToUser;
  // Global lock duration
  uint256 public lockDuration;

  // Operator
  mapping(address => bool) public isOperator;

  event UserDeposit(address indexed user, uint256 amount);
  event UserWithdraw(address indexed user, uint256 amount);
  event NewStartAndEndTimes(uint256 startTime, uint256 endTime);
  event NewFreezeTimes(uint256 freezeStartTime, uint256 freezeEndTime);

  /**
   * @dev Upgradable initializer
   */
  function __Staking_init(
    IERC20MetadataUpgradeable _stakedToken,
    IERC20MetadataUpgradeable _rewardToken,
    uint256 _maxStakedPerPool,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _maxStakedPerUser,
    uint256 _minDepositAmount,
    uint256 _withdrawTime,
    uint256 _withdrawMode,
    uint256 _fixedAPY,
    bool _isAutoCompound,
    address _admin
  ) external initializer {
    __Ownable_init();
    __ReentrancyGuard_init();

    stakedToken = _stakedToken;
    rewardToken = _rewardToken;
    maxStakedPerPool = _maxStakedPerPool;

    // 100% = 10000 = _RATE_NOMINATOR
    fixedAPY = _fixedAPY;
    isAutoCompound = _isAutoCompound;
    startTime = _startTime;
    endTime = _endTime;
    minDepositAmount = _minDepositAmount;
    withdrawTime = _withdrawTime;
    withdrawMode = _withdrawMode;

    if (_maxStakedPerUser > 0) {
      hasUserLimit = true;
      maxStakedPerUser = _maxStakedPerUser;
    }

    if (_admin != _msgSender()) {
      // Transfer ownership to the admin address who becomes owner of the contract
      transferOwnership(_admin);
    }
    enableLockToUser = true;
  }



  /**
   * @dev Function to add a account to blacklist
   */
  function fSetOperator(address _pAccount, bool _pStatus) external onlyOwner {
    require(isOperator[_pAccount] != _pStatus, "Added");
    isOperator[_pAccount] = _pStatus;
  }

  /*
   * @notice Compound mode is only enabled when stake token = reward token and isAutoCompound is true
   */
  function canCompound() public view returns (bool) {
    return address(stakedToken) == address(rewardToken) && isAutoCompound;
  }

  /*
   * @notice Update compound mode
   */
  function setCompound(bool _mode) external onlyOwner {
    isAutoCompound = _mode;
  }

  /*
   * @notice Get remaining reward
   */
  function getRemainingReward() public view returns (uint256) {
    if (maxRewardPerPool > claimedRewardPerPool) return maxRewardPerPool - claimedRewardPerPool;
    return 0;
  }

  /*
   * @notice View function to see pending reward on frontend.
   * @param _user: user address
   * @return Pending reward for a given user
   */
  function getPendingReward(address _user) public view returns (uint256) {
    UserInfo storage user = userInfo[_user];
    uint userReward;
    if (block.timestamp > user.lastRewardTime && currentStakedPerPool != 0) {
      uint256 multiplier = _getMultiplier(user.lastRewardTime, block.timestamp);
      if (multiplier == 0) return 0;
      if (canCompound()) {
        // APY = 100% = 1
        // SecondsPerYear = 365 * 24 * 60 * 60 = 31536000  (365 days)
        // Duration = n
        // InitialAmount = P
        // FinalAmount = P * ( 1 + APY/SecondsPerYear )^n
        // Compounded interest = FinalAmount - P;
        uint rate = rpow(WAD + (fixedAPY * WAD) / SECONDS_YEAR / _RATE_NOMINATOR, multiplier, WAD);
        userReward = wmul(user.amount, rate - WAD);
      } else {
        // FinalAmount = P * APY/SecondsPerYear * n
        // Compounded interest = FinalAmount - P;
        userReward = (user.amount * fixedAPY * multiplier) / SECONDS_YEAR / _RATE_NOMINATOR;
      }
    }
    return userReward;
  }

  /*
   * @notice Deposit staked tokens and collect reward tokens (if any)
   * @param _amount: amount to withdraw (in rewardToken)
   */
  function deposit(uint256 _amount) external nonReentrant {
    require(isFrozen() == false, "Deposit is frozen");
    if (maxStakedPerPool > 0) {
      require((currentStakedPerPool + _amount) <= maxStakedPerPool, "Exceed max staked tokens");
    }

    UserInfo storage user = userInfo[msg.sender];
    require((user.amount + _amount) >= minDepositAmount, "User amount below minimum");

    if (hasUserLimit) {
      require((_amount + user.amount) <= maxStakedPerUser, "User amount above limit");
    }

    user.depositTime = block.timestamp;

    uint256 pending;
    if (user.amount > 0) {
      pending = getPendingReward(msg.sender);
      if (pending > 0) {
        // If pool mode is non-compound -> transfer rewards to user
        // Otherwise, compound to user amount
        if (canCompound()) {
          user.amount += pending;
          currentStakedPerPool += pending;
          claimedRewardPerPool += pending;
        } else {
          _safeRewardTransfer(address(msg.sender), pending);
        }
        user.lastRewardTime = block.timestamp;
      }
    } else {
      if (user.registered == false) {
        userList.push(msg.sender);
        user.registered = true;
        user.addr = address(msg.sender);
        user.lastRewardTime = block.timestamp;
        // We're not apply lock per user this time
        user.lockDuration = 0;
      }
    }

    uint256 addedAmount_;
    if (_amount > 0) {
      // Check real amount to avoid taxed token
      uint256 previousBalance_ = stakedToken.balanceOf(address(this));
      stakedToken.safeTransferFrom(address(msg.sender), address(this), _amount);
      uint256 newBalance_ = stakedToken.balanceOf(address(this));
      addedAmount_ = newBalance_ - previousBalance_;

      user.amount += addedAmount_;
      currentStakedPerPool += addedAmount_;
    }
    _addUserLog(msg.sender, _amount, addedAmount_, pending, true);

    emit UserDeposit(msg.sender, _amount);
  }

  /*
   * @notice Withdraw staked tokens and collect reward tokens
   * @param _amount: amount to withdraw (in rewardToken)
   */
  function withdraw(uint256 _amount) external nonReentrant {
    require(isFrozen() == false, "Withdraw is frozen");
    bool isClaim = _amount == 0;

    UserInfo storage user = userInfo[msg.sender];
    if (withdrawMode == 0 || (withdrawMode == 1 && !isClaim) || (withdrawMode == 2 && isClaim)) {
      require(block.timestamp >= withdrawTime, "Withdraw not available");
      if (enableLockToUser) {
        require(block.timestamp >= user.depositTime + lockDuration, "Global lock");
      }
    }

    // Claim reward
    uint256 pending = getPendingReward(msg.sender);
    if (pending > 0) {
      // If pool mode is non-compound -> transfer rewards to user
      // Otherwise, compound to user amount
      if (canCompound()) {
        user.amount += pending;
        currentStakedPerPool += pending;
        claimedRewardPerPool += pending;
      } else {
        _safeRewardTransfer(address(msg.sender), pending);
      }
      user.lastRewardTime = block.timestamp;
    }

    // Unstake
    if (_amount > 0) {
      require(block.timestamp >= user.depositTime + user.lockDuration, "Locked");

      if (_amount > user.amount) {
        // Exit pool, withdraw all
        _amount = user.amount;
      }
      user.amount -= _amount;
      currentStakedPerPool -= _amount;
      stakedToken.safeTransfer(address(msg.sender), _amount);
    }

    _addUserLog(msg.sender, _amount, 0, pending, false);



    emit UserWithdraw(msg.sender, _amount);
  }



  /*
   * @notice Add user log
   */
  function _addUserLog(
    address _addr,
    uint256 _amount1,
    uint256 _amount2,
    uint256 _amount3,
    bool _isDeposit
  ) private {
    _userLogs.push(UserLog(_addr, _amount1, _amount2, _amount3, _isDeposit, block.timestamp));
  }

  /*
   * @notice Return length of user logs
   */
  function getUserLogLength() external view returns (uint) {
    return _userLogs.length;
  }

  /*
   * @notice View function to get user logs.
   * @param _offset: offset for paging
   * @param _limit: limit for paging
   * @return get users, next offset and total users
   */
  function getUserLogsPaging(uint _offset, uint _limit)
    external
    view
    returns (
      UserLog[] memory users,
      uint nextOffset,
      uint total
    )
  {
    uint totalUsers = _userLogs.length;
    if (_limit == 0) {
      _limit = 1;
    }

    if (_limit > totalUsers - _offset) {
      _limit = totalUsers - _offset;
    }

    UserLog[] memory values = new UserLog[](_limit);
    for (uint i = 0; i < _limit; i++) {
      values[i] = _userLogs[_offset + i];
    }

    return (values, _offset + _limit, totalUsers);
  }

  /*
   * @notice return length of user addresses
   */
  function getUserListLength() external view returns (uint) {
    return userList.length;
  }

  /*
   * @notice View function to get users.
   * @param _offset: offset for paging
   * @param _limit: limit for paging
   * @return get users, next offset and total users
   */
  function getUsersPaging(uint _offset, uint _limit)
    external
    view
    returns (
      UserInfo[] memory users,
      uint nextOffset,
      uint total
    )
  {
    uint totalUsers = userList.length;
    if (_limit == 0) {
      _limit = 1;
    }

    if (_limit > totalUsers - _offset) {
      _limit = totalUsers - _offset;
    }

    UserInfo[] memory values = new UserInfo[](_limit);
    for (uint i = 0; i < _limit; i++) {
      values[i] = userInfo[userList[_offset + i]];
    }

    return (values, _offset + _limit, totalUsers);
  }

  /*
   * @notice isFrozed returns if contract is frozen, user cannot call deposit, withdraw, emergencyWithdraw function
   * If this pool link with another ico project, the pool will be frozen when it's raising
   */
  function isFrozen() public view returns (bool) {
    return block.timestamp >= freezeStartTime && block.timestamp <= freezeEndTime;
  }

  /*
   * @notice Reset user state
   * @dev Needs to be for emergency.
   */
  function resetUserState(
    address _userAddress,
    uint256 _amount,
    uint256 _lastRewardTime,
    uint256 _depositTime,
    uint256 _lockDuration,
    bool _registered
  ) external onlyOwner {
    UserInfo storage user = userInfo[msg.sender];
    user.addr = _userAddress;
    user.amount = _amount;
    user.lastRewardTime = _lastRewardTime;
    user.depositTime = _depositTime;
    user.lockDuration = _lockDuration;
    user.registered = _registered;
  }

  /*
   * @notice Stop rewards
   * @dev Only callable by owner. Needs to be for emergency.
   */
  function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
    maxRewardPerPool -= _amount;
    rewardToken.safeTransfer(address(msg.sender), _amount);
  }

  /*
   * @dev Update lock to user mode
   */
  function setEnableLockToUser(bool _enable) external onlyOwner {
    enableLockToUser = _enable;
  }

  /*
   * @dev Update lock duration
   */
  function setLockDuration(uint256 _duration) external onlyOwner {
    lockDuration = _duration;
  }

  /*
   * @dev Reset user deposit time
   */
  function resetUserDepositTime(address _user, uint256 _time) external onlyOwner {
    userInfo[_user].depositTime = _time;
  }

  /**
   * @notice It allows the admin to reward tokens
   * @param _amount: amount of tokens
   * @dev This function is only callable by admin.
   */
  function addRewardTokens(uint256 _amount) external onlyOwner {
    // Check real amount to avoid taxed token
    uint256 previousBalance_ = rewardToken.balanceOf(address(this));
    rewardToken.safeTransferFrom(address(msg.sender), address(this), _amount);
    uint256 newBalance_ = rewardToken.balanceOf(address(this));
    uint256 addedAmount_ = newBalance_ - previousBalance_;

    maxRewardPerPool += addedAmount_;
  }

  /*
   * @notice Stop rewards
   * @dev Only callable by owner
   */
  function stopReward() external onlyOwner {
    endTime = block.timestamp;
  }

  /*
   * @notice Stop Freeze
   * @dev Only callable by owner
   */
  function stopFreeze() external onlyOwner {
    freezeStartTime = 0;
    freezeEndTime = 0;
  }

  /*
   * @notice Update pool limit per user
   * @dev Only callable by owner.
   * @param _hasUserLimit: whether the limit remains forced
   * @param _maxStakedPerUser: new pool limit per user
   */
  function updateMaxStakedPerUser(bool _hasUserLimit, uint256 _maxStakedPerUser) external onlyOwner {
    require(hasUserLimit, "Must be set");
    if (_hasUserLimit) {
      require(_maxStakedPerUser > maxStakedPerUser, "New limit must be higher");
      maxStakedPerUser = _maxStakedPerUser;
    } else {
      hasUserLimit = _hasUserLimit;
      maxStakedPerUser = 0;
    }
  }

  /*
   * @notice Update reward per block
   * @dev Only callable by owner.
   * @param _maxStakedPerPool: Max tokens can be staked to this pool
   */
  function updateMaxStakedPerPool(uint256 _maxStakedPerPool) external onlyOwner {
    maxStakedPerPool = _maxStakedPerPool;
  }

  /**
   * @notice It allows the admin to update start and end times
   * @dev This function is only callable by owner.
   * @param _startTime: the new start time
   * @param _endTime: the new end time
   */
  function updateStartAndEndTimes(uint256 _startTime, uint256 _endTime) external onlyOwner {
    require(block.timestamp > endTime, "Pool has started");
    require(_startTime < _endTime, "Invalid start and end time");
    endTime = _endTime;

    if (_startTime > block.timestamp) {
      startTime = _startTime;
    }
    emit NewStartAndEndTimes(_startTime, _endTime);
  }

  /**
   * @notice It allows the admin to update freeze start and end times
   * @dev This function is only callable by owner.
   * @param _freezeStartTime: the new freeze start time
   * @param _freezeEndTime: the new freeze end time
   */
  function updateFreezeTimes(uint256 _freezeStartTime, uint256 _freezeEndTime) external onlyOwner {
    require(_freezeStartTime < _freezeEndTime, "Invalid start and end time");
    require(block.timestamp < _freezeStartTime, "Invalid start and current");

    freezeStartTime = _freezeStartTime;
    freezeEndTime = _freezeEndTime;
    emit NewFreezeTimes(freezeStartTime, freezeEndTime);
  }

  /**
   * @notice Update minimum deposit amount
   * @dev This function is only callable by owner.
   * @param _minDepositAmount: the new minimum deposit amount
   */
  function updateMinDepositAmount(uint256 _minDepositAmount) external onlyOwner {
    minDepositAmount = _minDepositAmount;
  }

  /**
   * @dev Update withdraw config
   * @param _time: time for withdraw
   * @param _mode: withdraw mode
   * 0: Apply withdrawTime to both (stake + reward)
   * 1: Apply withdrawTime to stake
   * 2: Apply withdrawTime to reward
   */
  function updateWithdrawConfig(uint256 _time, uint256 _mode) external onlyOwner {
    withdrawTime = _time;
    withdrawMode = _mode;
  }

  /*
   * @notice Return reward multiplier over the given _from to _to time.
   * @param _from: time to start
   * @param _to: time to finish
   */
  function _getMultiplier(uint256 _from, uint256 _to) private view returns (uint256) {
    if (_from < startTime) _from = startTime;
    if (_to > endTime) _to = endTime;
    if (_from >= _to) return 0;
    return _to - _from;
  }

  /*
   * @notice transfer reward tokens.
   * @param _to: address where tokens will transfer
   * @param _amount: amount of tokens
   */
  function _safeRewardTransfer(address _to, uint256 _amount) private {
    uint256 rewardBal = rewardToken.balanceOf(address(this));
    uint256 remaining = getRemainingReward();
    if (remaining > rewardBal) {
      remaining = rewardBal;
    }

    if (_amount > remaining) {
      claimedRewardPerPool += remaining;
      rewardToken.safeTransfer(_to, remaining);
    } else {
      claimedRewardPerPool += _amount;
      rewardToken.safeTransfer(_to, _amount);
    }
  }
}