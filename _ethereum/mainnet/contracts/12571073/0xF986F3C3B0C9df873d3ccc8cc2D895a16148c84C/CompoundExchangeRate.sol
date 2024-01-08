// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ICToken.sol";
import "./ITrigger.sol";

/**
 * @notice Defines a trigger that is toggled if the Compound exchange rate decreases between consecutive checks. Under
 * normal operation, this value should only increase
 */
contract CompoundExchangeRate is ITrigger {
  uint256 internal constant WAD = 10**18;

  /// @notice Address of CToken market protected by this trigger
  ICToken public immutable market;

  /// @notice Last read exchangeRateStored
  uint256 public lastExchangeRate;

  /// @dev Due to rounding errors in the Compound Protocol, the exchangeRateStored may occassionally decrease by small
  /// amount even when nothing is wrong. A large, very conservative tolerance is applied to ensure we do not
  /// accidentally trigger in these cases. Even though a smaller tolerance would likely be ok, a non-trivial exploit
  ///  will most likely cause the exchangeRateStored to decrease by more than 10,000 wei
  uint256 public constant tolerance = 10000; // 10,000 wei tolerance

  /**
   * @param _market Is the address of the Compound market this trigger should protect
   * @dev For definitions of other constructor parameters, see ITrigger.sol
   */
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _description,
    uint256[] memory _platformIds,
    address _recipient,
    address _market
  ) ITrigger(_name, _symbol, _description, _platformIds, _recipient) {
    // Set market
    market = ICToken(_market);

    // Save current exchange rate (immutables can't be read at construction, so we don't use `market` directly)
    lastExchangeRate = ICToken(_market).exchangeRateStored();
  }

  /**
   * @dev Checks if a CToken's exchange rate decreased. The exchange rate should never decrease, but may occasionally
   * decrease slightly due to rounding errors
   * @return True if trigger condition occured (i.e. exchange rate decreased), false otherwise
   */
  function checkTriggerCondition() internal override returns (bool) {
    // Read this blocks exchange rate
    uint256 _currentExchangeRate = market.exchangeRateStored();

    // Check if current exchange rate is below current exchange rate, accounting for tolerance
    bool _status = _currentExchangeRate < (lastExchangeRate - tolerance);

    // Save the new exchange rate
    lastExchangeRate = _currentExchangeRate;

    // Return status
    return _status;
  }
}
