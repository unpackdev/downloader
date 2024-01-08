pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./ITrigger.sol";
import "./IRibbonVaultV2.sol";

/**
 * @notice Defines a trigger that is toggled if any of the following conditions occur:
 *   - Ribbon V2 vault share price drops >50%

 * @dev This trigger is for Ribbon Theta Vaults
 */
contract RibbonV2SharePrice is ITrigger {
  /// @notice Ribbon Theta Vault this trigger is for
  IRibbonVaultV2 public immutable market;

  /// @notice Last read pricePerShare
  uint256 public lastPricePerShare;

  /// @dev Scale used to define percentages. Percentages are defined as tolerance / scale
  uint256 public constant scale = 1000;

  /// @dev Tolerance for pricePerShare drop
  uint256 public constant tolerance = 500; // 500 / 1000 = 50% tolerance

  /**
   * @param _market Is the address of the Ribbon V2 vault this trigger should protect
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
    // Set vault
    market = IRibbonVaultV2(_market);

    // Save current share price (immutables can't be read at construction, so we don't use `market` directly)
    lastPricePerShare = IRibbonVaultV2(_market).pricePerShare();
  }

  /**
   * @dev Checks the Ribbon Vault pricePerShare
   */
  function checkTriggerCondition() internal override returns (bool) {
    // Read this blocks share price
    uint256 _currentPricePerShare = market.pricePerShare();

    // Check if current share price is below current share price, accounting for tolerance
    bool _status = _currentPricePerShare < ((lastPricePerShare * tolerance) / scale);

    // Save the new share price
    lastPricePerShare = _currentPricePerShare;

    // Return status
    return _status;
  }
}
