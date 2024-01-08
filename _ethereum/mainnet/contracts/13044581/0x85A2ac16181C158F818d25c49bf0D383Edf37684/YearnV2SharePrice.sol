pragma solidity ^0.8.5;

import "./IYVaultV2.sol";
import "./ITrigger.sol";

/**
 * @notice Defines a trigger that is toggled if the price per share for the V2 yVault decreases between consecutive
 * checks. Under normal operation, this value should only increase
 */
contract YearnV2SharePrice is ITrigger {
  uint256 internal constant WAD = 10**18;

  /// @notice Vault this trigger is for
  IYVaultV2 public immutable market;

  /// @notice Last read pricePerShare
  uint256 public lastPricePerShare;

  /// @dev In Yearn V2 vaults, the pricePerShare decreases immediately after a harvest, and typically ramps up over the
  /// next six hours. Therefore we cannot simply check that the pricePerShare increases. Instead, we consider the vault
  /// triggered if the pricePerShare drops by more than 50% from it's previous value. This is conservative, but
  /// previous Yearn bugs resulted in pricePerShare drops of 0.5% – 10%, and were only temporary drops with users able
  /// to be made whole. Therefore this trigger requires a large 50% drop to minimize false positives. The tolerance
  /// is defined such that we trigger if: currentPricePerShare < lastPricePerShare * tolerance / 1e18. This means
  /// if you want to trigger after a 20% drop, you should set the tolerance to 1e18 - 0.2e18 = 0.8e18 = 8e17
  uint256 public constant tolerance = 5e17; // 50%, represented on a scale where 1e18 = 100%

  /**
   * @param _market Is the address of the Yearn V2 vault this trigger should protect
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
    market = IYVaultV2(_market);

    // Save current share price (immutables can't be read at construction, so we don't use `market` directly)
    lastPricePerShare = IYVaultV2(_market).pricePerShare();
  }

  /**
   * @dev Checks the yVault pricePerShare
   */
  function checkTriggerCondition() internal override returns (bool) {
    // Read this blocks share price
    uint256 _currentPricePerShare = market.pricePerShare();

    // Check if current share price is below current share price, accounting for tolerance
    bool _status = _currentPricePerShare < ((lastPricePerShare * tolerance) / 1e18);

    // Save the new share price
    lastPricePerShare = _currentPricePerShare;

    // Return status
    return _status;
  }
}
