// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Math.sol";
import "./BaseUpgradeablePausable.sol";
import "./Pool.sol";
import "./Accountant.sol";
import "./CreditLine.sol";
import "./GoldfinchConfig.sol";

contract FakeV2CreditDesk is BaseUpgradeablePausable {
  uint256 public totalWritedowns;
  uint256 public totalLoansOutstanding;
  uint256 public constant SECONDS_PER_DAY = 60 * 60 * 24;
  GoldfinchConfig public config;

  struct Underwriter {
    uint256 governanceLimit;
    address[] creditLines;
  }

  struct Borrower {
    address[] creditLines;
  }

  event PaymentMade(
    address indexed payer,
    address indexed creditLine,
    uint256 interestAmount,
    uint256 principalAmount,
    uint256 remainingAmount
  );
  event PrepaymentMade(address indexed payer, address indexed creditLine, uint256 prepaymentAmount);
  event DrawdownMade(address indexed borrower, address indexed creditLine, uint256 drawdownAmount);
  event CreditLineCreated(address indexed borrower, address indexed creditLine);
  event PoolAddressUpdated(address indexed oldAddress, address indexed newAddress);
  event GovernanceUpdatedUnderwriterLimit(address indexed underwriter, uint256 newLimit);
  event LimitChanged(address indexed owner, string limitType, uint256 amount);

  mapping(address => Underwriter) public underwriters;
  mapping(address => Borrower) private borrowers;

  function initialize(address owner, GoldfinchConfig _config) public initializer {
    owner;
    _config;
    return;
  }

  function someBrandNewFunction() public pure returns (uint256) {
    return 5;
  }

  function getUnderwriterCreditLines(address underwriterAddress) public view returns (address[] memory) {
    return underwriters[underwriterAddress].creditLines;
  }
}
