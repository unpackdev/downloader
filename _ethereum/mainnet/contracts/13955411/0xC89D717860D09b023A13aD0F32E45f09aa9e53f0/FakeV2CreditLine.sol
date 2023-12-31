// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Pool.sol";
import "./BaseUpgradeablePausable.sol";

contract FakeV2CreditLine is BaseUpgradeablePausable {
  // Credit line terms
  address public borrower;
  address public underwriter;
  uint256 public limit;
  uint256 public interestApr;
  uint256 public paymentPeriodInDays;
  uint256 public termInDays;
  uint256 public lateFeeApr;

  // Accounting variables
  uint256 public balance;
  uint256 public interestOwed;
  uint256 public principalOwed;
  uint256 public termEndTime;
  uint256 public nextDueTime;
  uint256 public interestAccruedAsOf;
  uint256 public writedownAmount;
  uint256 public lastFullPaymentTime;

  function initialize(
    address owner,
    address _borrower,
    address _underwriter,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr
  ) public initializer {
    __BaseUpgradeablePausable__init(owner);
    borrower = _borrower;
    underwriter = _underwriter;
    limit = _limit;
    interestApr = _interestApr;
    paymentPeriodInDays = _paymentPeriodInDays;
    termInDays = _termInDays;
    lateFeeApr = _lateFeeApr;
    interestAccruedAsOf = block.timestamp;
  }

  function anotherNewFunction() external pure returns (uint256) {
    return 42;
  }

  function authorizePool(address) external view onlyAdmin {
    // no-op
    return;
  }
}
