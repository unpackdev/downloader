pragma solidity ^0.8.5;

import "./ICurvePool.sol";
import "./IERC20.sol";
import "./ITrigger.sol";
import "./IYVaultV2.sol";

/**
 * @notice Defines a trigger that is toggled if any of the following conditions occur:
 *   1. The price per share for the V2 yVault significantly decreases between consecutive checks. Under normal
 *      operation, this value should only increase. A decrease indicates something is wrong with the Yearn vault
 *   2. Curve 3Crypto token balances are significantly lower than what the pool expects them to be
 *   3. Curve 3Crypto virtual price drops significantly
 */
contract YearnCrv3Crypto is ITrigger {
  // --- Tokens ---
  // Token addresses
  IERC20 internal constant usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  IERC20 internal constant wbtc = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
  IERC20 internal constant weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  // Token indices in Curve pool arrays
  uint256 internal constant usdtIndex = 0;
  uint256 internal constant wbtcIndex = 1;
  uint256 internal constant wethIndex = 2;

  // --- Tolerances ---
  /// @dev Scale used to define percentages. Percentages are defined as tolerance / scale
  uint256 public constant scale = 1000;

  /// @dev In Yearn V2 vaults, the pricePerShare decreases immediately after a harvest, and typically ramps up over the
  /// next six hours. Therefore we cannot simply check that the pricePerShare increases. Instead, we consider the vault
  /// triggered if the pricePerShare drops by more than 50% from it's previous value. This is conservative, but
  /// previous Yearn bugs resulted in pricePerShare drops of 0.5% – 10%, and were only temporary drops with users able
  /// to be made whole. Therefore this trigger requires a large 50% drop to minimize false positives. The tolerance
  /// is defined such that we trigger if: currentPricePerShare < lastPricePerShare * tolerance / 1000. This means
  /// if you want to trigger after a 20% drop, you should set the tolerance to 1000 - 200 = 800
  uint256 public constant vaultTol = scale - 500; // 50% drop, represented on a scale where 1000 = 100%

  /// @dev Consider trigger toggled if Curve virtual price drops by this percentage. Similar to the Yearn V2 price
  /// per share, the virtual price is expected to decrease during normal operation, but it should never decrease by
  /// more than 50% during normal operation. Therefore we check for a 50% drop
  uint256 public constant virtualPriceTol = scale - 500; // 50% drop

  /// @dev Consider trigger toggled if Curve internal balances are lower than true balances by this percentage
  uint256 public constant balanceTol = scale - 500; // 50% drop

  // --- Trigger Data ---
  /// @notice Yearn vault this trigger is for
  IYVaultV2 public immutable vault;

  /// @notice Curve 3crypto pool used as a strategy by `vault`
  ICurvePool public immutable curve;

  /// @notice Last read pricePerShare
  uint256 public lastPricePerShare;

  /// @notice Last read curve virtual price
  uint256 public lastVirtualPrice;

  // --- Constructor ---

  /**
   * @param _vault Address of the Yearn V2 vault this trigger should protect
   * @param _curve Address of the Curve 3Crypto pool uses by the above Yearn vault
   * @dev For definitions of other constructor parameters, see ITrigger.sol
   */
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _description,
    uint256[] memory _platformIds,
    address _recipient,
    address _vault,
    address _curve
  ) ITrigger(_name, _symbol, _description, _platformIds, _recipient) {
    // Set vault
    vault = IYVaultV2(_vault);
    curve = ICurvePool(_curve);

    // Save current values (immutables can't be read at construction, so we don't use `vault` or `curve` directly)
    lastPricePerShare = IYVaultV2(_vault).pricePerShare();
    lastVirtualPrice = ICurvePool(_curve).get_virtual_price();
  }

  // --- Trigger condition ---

  /**
   * @dev Checks the yVault pricePerShare
   */
  function checkTriggerCondition() internal override returns (bool) {
    // Read this blocks share price and virtual price
    uint256 _currentPricePerShare = vault.pricePerShare();
    uint256 _currentVirtualPrice = curve.get_virtual_price();

    // Check trigger conditions. We could check one at a time and return as soon as one is true, but it is convenient
    // to have the data that caused the trigger saved into the state, so we don't do that
    bool _statusVault = _currentPricePerShare < ((lastPricePerShare * vaultTol) / scale);
    bool _statusVirtualPrice = _currentVirtualPrice < ((lastVirtualPrice * virtualPriceTol) / scale);
    bool _statusBalances = checkCurveBalances();

    // Save the new data
    lastPricePerShare = _currentPricePerShare;
    lastVirtualPrice = _currentVirtualPrice;

    // Return status
    return _statusVault || _statusVirtualPrice || _statusBalances;
  }

  /**
   * @dev Checks if the Curve internal balances are significantly lower than the true balances
   * @return True if balances are out of tolerance and trigger should be toggled
   */
  function checkCurveBalances() internal view returns (bool) {
    return
      (usdt.balanceOf(address(curve)) < ((curve.balances(usdtIndex) * balanceTol) / scale)) ||
      (wbtc.balanceOf(address(curve)) < ((curve.balances(wbtcIndex) * balanceTol) / scale)) ||
      (weth.balanceOf(address(curve)) < ((curve.balances(wethIndex) * balanceTol) / scale));
  }
}
