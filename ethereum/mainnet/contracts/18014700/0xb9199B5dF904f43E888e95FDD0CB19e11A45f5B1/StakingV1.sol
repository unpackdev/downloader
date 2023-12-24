// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IStakingV1.sol";
import "./Address.sol";
import "./Authorizable.sol";
import "./Pausable.sol";
import "./IDCounter.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./Util.sol";
import "./Math.sol";

struct StakerData {
  bool autoClaimOptOut;
  /** amount currently staked */
  uint256 amount;
  /** total amount of eth claimed */
  uint256 totalClaimed;
  uint256 totalExcluded;
  uint256 lastDeposit;
  uint256 lastClaim;
}

/**
 * eth reflection - also base contract for token reflection
 */
contract StakingV1 is IStakingV1, Authorizable, Pausable, ReentrancyGuard {
  /** libraries */
  using Address for address payable;
  using SafeERC20 for IERC20;

  constructor(
    address owner_,
    address tokenAddress_,
    uint16 lockDurationDays_
  ) Authorizable(owner_) {
    //
    _token = IERC20(tokenAddress_);
    _decimals = _token.decimals();
    _lockDurationDays = lockDurationDays_;
  }

  /** @dev reference to the staked token */
  IERC20 internal immutable _token;

  /** @dev cached copy of the staked token decimals value */
  uint8 internal immutable _decimals;

  uint16 internal _lockDurationDays;

  uint256 internal _totalStaked;
  uint256 internal _totalClaimed;

  uint256 internal _lastBalance;
  uint256 internal _rewardsPerToken;
  uint256 internal _accuracy = 10 ** 18;

  /** @dev current number of stakers */
  uint64 internal _currentNumStakers;

  /** @dev total number of stakers - not reduced when a staker withdraws all */
  uint64 internal _totalNumStakers;

  /** @dev used to limit the amount of gas spent during auto claim */
  uint256 internal _autoClaimGasLimit = 200000;

  /** @dev current index used for auto claim iteration */
  uint64 internal _autoClaimIndex;

  bool internal _autoClaimEnabled = true;

  /** @dev should autoClaim be run automatically on deposit? */
  bool internal _autoClaimOnDeposit = true;

  /** @dev should autoClaim be run automatically on manual claim? */
  bool internal _autoClaimOnClaim = true;

  /** @dev account => staker data */
  mapping(address => StakerData) internal _stakers;

  /** @dev this is essentially an index in the order that new users are added. */
  mapping(uint64 => address) internal _autoClaimQueue;
  /** @dev reverse lookup for _autoClaimQueue. allows getting index by address */
  mapping(address => uint64) internal _autoClaimQueueReverse;

  // modifier autoClaimAfter {
  //   _;
  //   _autoClaim();
  // }

  function _stakingType() internal virtual view returns (uint8) {
    return 0;
  }

  // function stakingType() external virtual override view returns (uint8) {
  //   return _stakingType();
  // }

  function _totalRewards() internal virtual view returns (uint256) {
    return _getRewardsBalance() + _totalClaimed;
  }

  function rewardsAreToken() public virtual override pure returns (bool) {
    return false;
  }

  function autoClaimEnabled() external virtual override view returns (bool) {
    return _autoClaimEnabled;
  }

  function setAutoClaimEnabled(bool value) external virtual override {
    _autoClaimEnabled = value;
  }

  function accuracy() external virtual override view returns (uint256) {
    return _accuracy;
  }

  function setAccuracy(uint256 value) external virtual override onlyAuthorized {
    _rewardsPerToken = _rewardsPerToken * value / _accuracy;
    _accuracy = value;
  }

  function setAutoClaimOnDeposit(bool value) external virtual override onlyAuthorized {
    _autoClaimOnDeposit = value;
  }

  function setAutoClaimOnClaim(bool value) external virtual override onlyAuthorized {
    _autoClaimOnClaim = value;
  }

  function getAutoClaimOptOut(address account) external virtual override view returns (bool) {
    return _stakers[account].autoClaimOptOut;
  }

  function setAutoClaimOptOut(bool value) external virtual override {
    _stakers[_msgSender()].autoClaimOptOut = value;
  }

  /**
   * @dev allow removing the lock duration, but not setting it directly.
   * this removes the possibility of creating a long lock duration after
   * people have deposited their tokens, essentially turning the staking
   * contract into a honeypot.
   *
   * removing the lock is necessary in case of emergencies,
   * like migrating to a new staking contract.
   */
  function removeLockDuration() external virtual override onlyAuthorized {
    _lockDurationDays = 0;
  }

  function getPlaceInQueue(address account) external virtual override view returns (uint256) {
    if (_autoClaimQueueReverse[account] >= _autoClaimIndex)
      return _autoClaimQueueReverse[account] - _autoClaimIndex;

    return _totalNumStakers - (_autoClaimIndex - _autoClaimQueueReverse[account]);
  }

  function autoClaimGasLimit() external virtual override view returns (uint256) {
    return _autoClaimGasLimit;
  }

  function setAutoClaimGasLimit(uint256 value) external virtual override onlyAuthorized {
    _autoClaimGasLimit = value;
  }

  /** @return the address of the staked token */
  function token() external virtual override view returns (address) {
    return address(_token);
  }

  function getStakingData() external virtual override view returns (
    uint8 stakingType,
    address stakedToken,
    uint8 decimals,
    uint256 totalStaked,
    uint256 totalRewards,
    uint256 totalClaimed
  ) {
    stakingType = _stakingType();
    stakedToken = address(_token);
    decimals = _decimals;
    totalStaked = _totalStaked;
    totalRewards = _totalRewards();
    totalClaimed = _totalClaimed;
  }

  function getStakingDataForAccount(address account) external virtual override view returns (
    uint256 amount,
    uint64 lastClaimedAt,
    uint256 pendingRewards,
    uint256 totalClaimed
  ) {
    amount = _stakers[account].amount;
    lastClaimedAt = uint64(_lastClaimTime(account));
    pendingRewards = _pending(account);
    totalClaimed = _stakers[account].totalClaimed;
  }

  function _earned(address account) internal virtual view returns (uint256) {
    if (_stakers[account].amount == 0)
      return 0;

    uint256 rewards = _getCumalativeRewards(_stakers[account].amount);
    uint256 excluded = _stakers[account].totalExcluded;

    return rewards > excluded ? rewards - excluded : 0;
  }

  function _pending(address account) internal virtual view returns (uint256) {
    if (_stakers[account].amount == 0)
      return 0;
    
    uint256 rewards = _stakers[account].amount * _getRewardsPerToken() / _accuracy;
    uint256 excluded = _stakers[account].totalExcluded;

    return rewards > excluded ? rewards - excluded : 0;
  }

  function pending(address account) external virtual override view returns (uint256) {
    return _pending(account);
  }

  function _sendRewards(address account, uint256 amount) internal virtual returns (bool) {
    // payable(account).sendValue(amount);

    // don't revert on failure, otherwise we risk dos attacks
    (bool success,) = account.call{value: amount}("");

    return success;
  }

  function _claim(address account) internal virtual returns (bool) {
    _updateRewards();

    uint256 pendingRewards = _earned(account);

    if (_stakers[account].amount == 0 || pendingRewards == 0)
      return false;

    uint256 lastLastClaim = _stakers[account].lastClaim;

    _stakers[account].totalClaimed += pendingRewards;
    _stakers[account].totalExcluded += pendingRewards;
    _stakers[account].lastClaim = block.timestamp;
    _totalClaimed += pendingRewards;

    // reset everything if the transfer failed
    // is this -really- safe?
    if (!_sendRewards(account, pendingRewards)) {
      _stakers[account].totalClaimed -= pendingRewards;
      _stakers[account].totalExcluded -= pendingRewards;
      _stakers[account].lastClaim = lastLastClaim;
      _totalClaimed -= pendingRewards;

      return false;
    }

    _updateRewards();

    emit ClaimedRewards(account, pendingRewards);

    return true;
  }

  function claimFor(address account, bool revertOnFailure, bool doAutoClaim) external virtual override nonReentrant {
    if (revertOnFailure)
      require(_claim(account), "Claim failed");
    else
      _claim(account);

    if (doAutoClaim) _autoClaim();
  }

  function claim() external virtual override nonReentrant {
    require(_claim(_msgSender()), "Claim failed");

    if (_autoClaimOnClaim) _autoClaim();
  }

  function _deposit(address account, uint256 amount) internal virtual onlyNotPaused {
    require(amount != 0, "Deposit amount cannot be 0");

    // claim before depositing
    _claim(account);

    if (_autoClaimQueueReverse[account] == 0) {
      _totalNumStakers++;
      _currentNumStakers++;
      _autoClaimQueueReverse[account] = _totalNumStakers;
      _autoClaimQueue[_totalNumStakers] = account;
    }

    _stakers[account].amount += amount;
    _stakers[account].totalExcluded = _getCumalativeRewards(_stakers[account].amount);
    _stakers[account].lastDeposit = block.timestamp;
    _totalStaked += amount;

    // store previous balance to determine actual amount transferred
    uint256 oldBalance = _token.balanceOf(address(this));
    // make the transfer
    _token.safeTransferFrom(account, address(this), amount);
    // check for lost tokens - this is an unsupported situation currently.
    // tokens could be lost during transfer if the token has tax.
    require(
      amount == _token.balanceOf(address(this)) - oldBalance,
      "Lost tokens during transfer"
    );

    emit DepositedTokens(account, amount);
  }

  /**
   * @dev deposit amount of tokens to the staking pool.
   * reverts if tokens are lost during transfer.
   */
  function deposit(uint256 amount) external virtual override nonReentrant {
    _deposit(_msgSender(), amount);
  }

  function _getUnlockTime(address account) internal virtual view returns (uint64) {
    return _lockDurationDays == 0 ? 0 : uint64(_lastClaimTime(account)) + (uint64(_lockDurationDays) * 86400);
  }

  function getUnlockTime(address account) external virtual override view returns (uint64) {
    uint64 unlockTime = _getUnlockTime(account);
    if (unlockTime <= block.timestamp) return 0;
    return unlockTime;
  }

  function _withdraw(address account, uint256 amount, bool claimFirst) internal virtual {
    require(
      _stakers[account].amount != 0 && _stakers[account].amount >= amount,
      "Attempting to withdraw too many tokens"
    );

    if (_lockDurationDays != 0)
      require(
        block.timestamp > _getUnlockTime(account),
        "Wait for tokens to unlock before withdrawing"
      );

    if (claimFirst)
      _claim(account);

    _stakers[account].amount -= amount;
    _stakers[account].totalExcluded = _getCumalativeRewards(_stakers[account].amount);
    _totalStaked -= amount;

    if (_stakers[account].amount == 0) {
      // decrement current number of stakers
      _currentNumStakers--;
      // remove account from auto claim queue
      _autoClaimQueue[_autoClaimQueueReverse[account]] = address(0);
      _autoClaimQueueReverse[account] = 0;
    }

    // transfer tokens after modifying internal state
    _token.safeTransfer(account, amount);

    emit WithdrewTokens(account, amount);
  }

  function withdraw(uint256 amount) external virtual override nonReentrant {
    _withdraw(_msgSender(), amount, true);
  }

  /** this withdraws all and skips the claiming step */
  function emergencyWithdraw() external virtual override nonReentrant {
    _withdraw(_msgSender(), _stakers[_msgSender()].amount, false);
  }

  function _lastClaimTime(address account) internal virtual view returns (uint256) {
    return _stakers[account].lastClaim;
  }

  function _depositRewards(address account, uint256 amount) internal virtual onlyNotPaused {
    require(amount != 0, "Receive value cannot be 0");

    // _totalRewards += amount;

    emit DepositedEth(account, amount);
  }

  function _autoClaim() internal virtual {
    if (!_autoClaimEnabled) return;

    uint256 startingGas = gasleft();
    uint256 iterations = 0;

    while (startingGas - gasleft() < _autoClaimGasLimit && iterations++ < _totalNumStakers) {
      // use unchecked here so index can overflow, since it doesn't matter.
      // this prevents the incredibly unlikely future problem of running
      // into an overflow error and probably saves some gas
      uint64 index;
      unchecked {
        index = _autoClaimIndex++;
      }

      address autoClaimAddress = _autoClaimQueue[1 + (index % _totalNumStakers)];

      if (!_stakers[autoClaimAddress].autoClaimOptOut)
        _claim(autoClaimAddress);
    }
  }

  /** @dev allow anyone to process autoClaim functionality manually */
  function processAutoClaim() external virtual override nonReentrant {
    _autoClaim();
  }

  function _getRewardsPerToken() internal virtual view returns (uint256) {
    uint256 rewardsBalance = _getRewardsBalance();

    if (rewardsBalance < _lastBalance || _totalStaked == 0)
      return 0;

    return _rewardsPerToken + ((rewardsBalance - _lastBalance) * _accuracy / _totalStaked);
  }

  function _updateRewards() internal virtual {
    uint256 rewardsBalance = _getRewardsBalance();

    if (rewardsBalance > _lastBalance && _totalStaked != 0)
      _rewardsPerToken += (rewardsBalance - _lastBalance) * _accuracy / _totalStaked;

    if (_totalStaked != 0)
      _lastBalance = rewardsBalance;
  }

  function _getCumalativeRewards(uint256 amount) internal virtual view returns (uint256) {
    return amount * _rewardsPerToken / _accuracy;
  }

  function _getRewardsBalance() internal virtual view returns (uint256) {
    return address(this).balance;
  }

  receive() external virtual payable nonReentrant {
    _depositRewards(_msgSender(), msg.value);

    if (_autoClaimOnDeposit) _autoClaim();
  }
}
