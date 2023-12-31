// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./PoolBase.sol";
import "./IInterestRateModel.sol";

error GTO(uint256 value);

/// @notice This contract describes pool's configuration functions
abstract contract PoolConfiguration is PoolBase {
  /// @notice Pool maximum capacity, blocking overflow deposits
  uint256 public maximumCapacity;

  /// @notice Pool utilization that to what borrower should repay after entering provisionalDefaultUtilization (as 18-digit decimal)
  uint256 public provisionalRepaymentUtilization;

  /// @notice Event emitted when pool's capacity is updated
  /// @param newCapacity New capacity of the pool
  event MaximumCapacityChanged(uint256 newCapacity);

  /// @notice Modifier to check if amount is not greater than 1e18
  modifier nonGTO(uint256 amount) {
    if (amount > 1e18) revert GTO(amount);
    _;
  }

  /// @notice Function is used to update pool's manager (only called through factory)
  /// @param manager_ New manager of the pool
  function setManager(address manager_) external onlyFactory nonZeroAddress(manager_) {
    manager = manager_;
  }

  /// @notice Function is used to update pool's interest rate model (only called by governor)
  /// @param interestRateModel_ New IRM of the pool
  function setInterestRateModel(
    IInterestRateModel interestRateModel_
  ) external onlyGovernor nonZeroAddress(address(interestRateModel_)) {
    _accrueInterest();
    interestRateModel = interestRateModel_;
  }

  /// @notice Function is used to update pool's reserve factor (only called by governor)
  /// @param reserveFactor_ New reserve factor of the pool
  function setReserveFactor(
    uint256 reserveFactor_
  ) external onlyGovernor nonGTO(reserveFactor_ + insuranceFactor) {
    reserveFactor = reserveFactor_;
  }

  /// @notice Function is used to update pool's insurance factor (only called by governor)
  /// @param insuranceFactor_ New insurance factor of the pool
  function setInsuranceFactor(
    uint256 insuranceFactor_
  ) external onlyGovernor nonGTO(reserveFactor + insuranceFactor_) {
    insuranceFactor = insuranceFactor_;
  }

  /// @notice Function is used to update pool's warning utilization (only called by governor)
  /// @param warningUtilization_ New warning utilization of the pool
  function setWarningUtilization(
    uint256 warningUtilization_
  ) external onlyGovernor nonGTO(warningUtilization_) {
    _accrueInterest();
    warningUtilization = warningUtilization_;
    _checkUtilization();
  }

  /// @notice Function is used to update pool's provisional repayment utilization (only called by governor)
  /// @param provisionalRepaymentUtilization_ New provisional repayment utilization of the pool
  function setProvisionalRepaymentUtilization(
    uint256 provisionalRepaymentUtilization_
  ) external onlyGovernor nonGTO(provisionalRepaymentUtilization_) {
    _accrueInterest();
    provisionalRepaymentUtilization = provisionalRepaymentUtilization_;
    _checkUtilization();
  }

  /// @notice Function is used to update pool's provisional default utilization (only called by governor)
  /// @param provisionalDefaultUtilization_ New provisional default utilization of the pool
  function setProvisionalDefaultUtilization(
    uint256 provisionalDefaultUtilization_
  ) external onlyGovernor nonGTO(provisionalDefaultUtilization_) {
    _accrueInterest();
    provisionalDefaultUtilization = provisionalDefaultUtilization_;
    _checkUtilization();
  }

  /// @notice Function is used to update pool's warning grace period (only called by governor)
  /// @param warningGracePeriod_ New warning grace period of the pool
  function setWarningGracePeriod(uint256 warningGracePeriod_) external onlyGovernor {
    _accrueInterest();
    warningGracePeriod = warningGracePeriod_;
    _checkUtilization();
  }

  /// @notice Function is used to update pool's max inactive period (only called by governor)
  /// @param maxInactivePeriod_ New max inactive period of the pool
  function setMaxInactivePeriod(uint256 maxInactivePeriod_) external onlyGovernor {
    _accrueInterest();
    maxInactivePeriod = maxInactivePeriod_;
  }

  /// @notice Function is used to update pool's period to start auction (only called by governor)
  /// @param periodToStartAuction_ New period to start auction of the pool
  function setPeriodToStartAuction(uint256 periodToStartAuction_) external onlyGovernor {
    periodToStartAuction = periodToStartAuction_;
  }

  /// @notice Function is called by governor or manager to change max pool cap
  /// @param capacity New max pool capacity. 0 means no limit
  function setMaxCapacity(uint256 capacity) external {
    require(msg.sender == factory.owner() || msg.sender == manager, 'OGM');

    maximumCapacity = capacity;

    emit MaximumCapacityChanged(capacity);
  }

  /// @notice Function is used to update pool's symbol (only called by governor)
  /// @param symbol_ New symbol of the pool
  function setSymbol(string memory symbol_) external onlyGovernor {
    _symbol = symbol_;
  }
}
