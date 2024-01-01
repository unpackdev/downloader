// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

import "./IRSRV.sol";
import "./IReserveBrokerage.sol";
import "./IReserve.sol";

contract ReserveBrokerage is IReserveBrokerage, Ownable, ReentrancyGuard {
  using SafeMath for uint;
  using SafeERC20 for IERC20;

  IRSRV public immutable rsrv;
  IReserve public reserve;
  address public constant deadAddress = address(0xdead);

  struct VestingOption {
    bool enabled;
    uint duration;
    uint bonus;
  }

  struct UserVesting {
    uint id;
    uint option;
    uint burnedAmount;
    uint timestamp;
    uint released;
  }

  mapping (uint => VestingOption) public vestingOptions;
  mapping (address => UserVesting[]) public userVestings;

  uint public totalVestingOptions;
  uint public totalUserVestings;
  uint public totalDeposited;
  uint public totalIssued;

  uint private constant DENOMINATOR = 10000;
  uint private constant MAX_VESTINGS = 20;

  /** EVENTS **/

  event BurnedAndVested(
    address indexed account,
    uint amount,
    uint option
  );

  event Claimed(
    address indexed account,
    uint amount
  );

  constructor (
    address _rsrv,
    address _reserve
  ) {
    rsrv = IRSRV(_rsrv);
    reserve = IReserve(_reserve);

    vestingOptions[0] = VestingOption(true, 1 weeks, 1000); // true, 1 weeks, 1000
    vestingOptions[1] = VestingOption(true, 2 weeks, 2500); // true, 2 weeks, 2500
    vestingOptions[2] = VestingOption(true, 3 weeks, 5000); // true, 3 weeks, 5000
    totalVestingOptions = 3;
  }

  /** VIEW FUNCTIONS **/

  function getUserVestingsCount(address account) public view returns (uint) {
    return userVestings[account].length;
  }

  function getReceivableAmount(uint amount, uint period) public view returns (uint) {
    return amount
      .mul(vestingOptions[period].bonus.add(DENOMINATOR))
      .div(DENOMINATOR);
  }

  function getAllVestings(address account) external view returns (UserVesting[] memory vestings, uint[] memory vestedAmounts) {
    uint length = getUserVestingsCount(account);
    vestings = new UserVesting[](length);
    vestedAmounts = new uint[](length);

    for (uint i; i < length; i++) {
      vestings[i] = userVestings[account][i];
      vestedAmounts[i] = _getUserVested(account, i);
    }
  }

  function totalVestedAmount(address account) external view returns (uint rewards) {
    uint length = getUserVestingsCount(account);

    for (uint i; i < length; i++) {
      rewards = rewards.add(_getUserVested(account, i));
    }
  }

  function _getTokenAmount(address account, uint index) internal view returns (uint) {
    return userVestings[account][index].burnedAmount
      .mul(vestingOptions[userVestings[account][index].option].bonus.add(DENOMINATOR))
      .div(DENOMINATOR);
  }

  function _getVestingPeriod(address account, uint index) internal view returns (uint) {
    return vestingOptions[userVestings[account][index].option].duration;
  }

  function _getUserVested(address account, uint index) internal view returns (uint releasableAmount) {
    uint amount = _getTokenAmount(account, index);
    if (amount > 0) {
      uint alreadyReleased = userVestings[account][index].released;
      uint vestedAmount = _getVestedAmount(amount, _getVestingPeriod(account, index), userVestings[account][index].timestamp, block.timestamp);
      releasableAmount = vestedAmount.sub(alreadyReleased);
    } else {
      releasableAmount = 0;
    }
  }

  function _getVestedAmount(uint _totalAmount, uint _period, uint _start, uint _timestamp) internal pure returns (uint) {
    if (_timestamp < _start) {
      return 0;
    } else if (_timestamp > _start + _period) {
      return _totalAmount;
    } else {
      return (_totalAmount * (_timestamp - _start)) / _period;
    }
  }

  function _getVestingOption(uint period) internal view returns (bool found, uint id) {
    for (uint index = 0; index < totalVestingOptions; index++) {
      if (vestingOptions[index].duration == period) {
        found = true;
        id = index;
        break;
      }
    }
  }

  /** INTERNAL FUNCTIONS **/

  function _burnAndVest(uint amount, uint period, address account) internal {
    require (userVestings[account].length < MAX_VESTINGS, "Too many active vestings for this account");
    require (amount > 0, "Amount must be greater than zero");

    uint id = totalUserVestings;
    (bool found, uint option) = _getVestingOption(period);
    require (found, "Vesting option not found");

    UserVesting memory userVesting = UserVesting(
      id,
      option,
      amount,
      block.timestamp,
      0
    );

    uint receivableAmount = getReceivableAmount(amount, period);
    require (totalIssued.add(receivableAmount) <= totalDeposited, "Not enough balance to cover receivable amount");
    totalIssued = totalIssued.add(receivableAmount);

    userVestings[account].push(userVesting);
    totalUserVestings = totalUserVestings.add(1);
    emit BurnedAndVested(account, amount, option);
  }

  function _removeVesting(address account, uint id) internal {
    uint length = getUserVestingsCount(account);
    for (uint i; i < length; i++) {
      if (userVestings[account][i].id == id) {
        userVestings[account][i] = userVestings[account][length - 1];
        userVestings[account].pop();
        break;
      }
    }
  }

  function _cleanup(address account) internal {
    uint length = getUserVestingsCount(account);
    uint count;
    for (uint i; i < length; i++) {
      if (userVestings[account][i].released == _getTokenAmount(account, i)) {
        count = count.add(1);
      }
    }

    if (count > 0) {
      uint[] memory idsToRemove = new uint[](count);
      uint index;

      for (uint i; i < length; i++) {
        if (userVestings[account][i].released == _getTokenAmount(account, i)) {
          idsToRemove[index] = userVestings[account][i].id;
          index = index.add(1);
        }
      }

      for (uint j = 0; j < idsToRemove.length; j++) {
        _removeVesting(account, idsToRemove[j]);
      }
    }
  }

  function _claim(address account) internal returns (uint rewards) {
    uint length = getUserVestingsCount(account);
    
    for (uint i; i < length; i++) {
      uint vestedAmount = _getUserVested(account, i);
      if (vestedAmount > 0) {
        userVestings[account][i].released = userVestings[account][i].released.add(vestedAmount);
        rewards = rewards.add(vestedAmount);
      }
    }

    _cleanup(account);
  }

  /** EXTERNAL FUNCTIONS **/

  function burnAndVest(uint amount, uint period) external isValidVestingOption(period) nonReentrant {
    SafeERC20.safeTransferFrom(rsrv, _msgSender(), deadAddress, amount);
    _burnAndVest(amount, period, _msgSender());
  }

  function burnAndVest(uint amount, uint period, address account) external isValidVestingOption(period) {
    require (_msgSender() == address(reserve), "Only reserve can call this function");
    _burnAndVest(amount, period, account);
  }

  function claim() external nonReentrant {
    uint rewards = _claim(_msgSender());
    if (rewards > 0) {
      SafeERC20.safeTransfer(rsrv, _msgSender(), rewards);
      emit Claimed(_msgSender(), rewards);
    }
  }

  function claim(uint amount, uint period) external nonReentrant {
    require (amount > 0, "Amount must be greater than zero");

    uint rewards = _claim(_msgSender());
    require (rewards >= amount, "Not enough rewards to cover amount");

    SafeERC20.safeTransfer(rsrv, deadAddress, amount);
    if (rewards > amount) {
      SafeERC20.safeTransfer(rsrv, _msgSender(), rewards.sub(amount));
      emit Claimed(_msgSender(), rewards.sub(amount));
    }
    _burnAndVest(amount, period, _msgSender());
  }

  function purchase(uint id, uint count) external nonReentrant {
    require (id < reserve.totalBankTypes(), "Invalid id");
    require (count > 0, "Count must be greater than zero");

    uint rewards = _claim(_msgSender());
    uint cost = reserve.claimBank(_msgSender(), id, count);
    require (rewards >= cost, "Rewards do not cover the purchase cost");

    SafeERC20.safeTransfer(rsrv, deadAddress, cost);
    if (rewards > cost) {
      SafeERC20.safeTransfer(rsrv, _msgSender(), rewards.sub(cost));
      emit Claimed(_msgSender(), rewards.sub(cost));
    }
  }

  function upgrade(uint id, uint count) external nonReentrant {
    require (id < reserve.totalBankTypes(), "Invalid id");
    require (count > 0, "Count must be greater than zero");

    uint rewards = _claim(_msgSender());
    uint cost = reserve.claimUpgrade(_msgSender(), id, count);
    require (rewards >= cost, "Rewards do not cover the upgrade cost");

    SafeERC20.safeTransfer(rsrv, deadAddress, cost);
    if (rewards > cost) {
      SafeERC20.safeTransfer(rsrv, _msgSender(), rewards.sub(cost));
      emit Claimed(_msgSender(), rewards.sub(cost));
    }
  }
  
  function depositTokens(uint amount) external {
    SafeERC20.safeTransferFrom(rsrv, _msgSender(), address(this), amount);
    totalDeposited = totalDeposited.add(amount);
  }

  /** RESTRICTED FUNCTIONS **/

  function setReserve(address _reserve) external onlyOwner {
    require (_reserve != address(0), "Invalid reserve address");

    reserve = IReserve(_reserve);
  }

  function setVestingOption(uint id, bool enabled, uint duration, uint bonus) external onlyOwner {
    require (id <= totalVestingOptions, "Invalid vesting option id");

    if (id < totalVestingOptions) {
      vestingOptions[id] = VestingOption(enabled, duration, bonus);
    } else {
      vestingOptions[id] = VestingOption(enabled, duration, bonus);
      totalVestingOptions = totalVestingOptions.add(1);
    }
  }

  function recoverTokens(address token) external onlyOwner {
    SafeERC20.safeTransfer(IERC20(token), owner(), IERC20(token).balanceOf(address(this)));
  }

  /** MODIFIERS **/

  modifier isValidVestingOption(uint period) {
    bool found = false;
    for (uint index = 0; index < totalVestingOptions; index++) {
      if (vestingOptions[index].duration == period && vestingOptions[index].enabled) found = true;
    }

    require (found, "Vesting period not found or disabled");
    _;
  }
}