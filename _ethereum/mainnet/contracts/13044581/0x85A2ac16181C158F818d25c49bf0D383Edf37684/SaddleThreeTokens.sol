pragma solidity ^0.8.6;

import "./ISaddlePool.sol";
import "./IERC20.sol";
import "./ITrigger.sol";
import "./IYVaultV2.sol";

/**
 * @notice Defines a trigger that is toggled if any of the following conditions occur:
 *   1. Saddle token balances are significantly lower than what the pool expects them to be
 *   2. Saddle virtual price drops significantly
 * @dev This trigger is for Yearn V2 Vaults that use a Saddle pool with two underlying tokens
 */
contract SaddleThreeTokens is ITrigger {
  // --- Tokens ---
  // Token addresses
  IERC20 internal immutable token0;
  IERC20 internal immutable token1;
  IERC20 internal immutable token2;

  // --- Tolerances ---
  /// @dev Scale used to define percentages. Percentages are defined as tolerance / scale
  uint256 public constant scale = 1000;

  /// @dev Consider trigger toggled if Saddle virtual price drops by more than this percentage.
  uint256 public constant virtualPriceTol = scale - 500; // 50% drop

  /// @dev Consider trigger toggled if Saddle internal balances are lower than true balances by this percentage
  uint256 public constant balanceTol = scale - 500; // 50% drop

  // --- Trigger Data ---
  /// @notice Saddle pool to protect
  ISaddlePool public immutable saddle;

  /// @notice Last read Saddle virtual price
  uint256 public lastVirtualPrice;

  // --- Constructor ---
  /**
   * @param _saddle Address of the Saddle pool, must contain three underlying tokens
   * @dev For definitions of other constructor parameters, see ITrigger.sol
   */
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _description,
    uint256[] memory _platformIds,
    address _recipient,
    address _saddle
  ) ITrigger(_name, _symbol, _description, _platformIds, _recipient) {
    // Set trigger data
    saddle = ISaddlePool(_saddle);
    token0 = IERC20(ISaddlePool(_saddle).getToken(0));
    token1 = IERC20(ISaddlePool(_saddle).getToken(1));
    token2 = IERC20(ISaddlePool(_saddle).getToken(2));

    // Save current values (immutables can't be read at construction, so we don't use `vault` or `saddle` directly)
    lastVirtualPrice = ISaddlePool(_saddle).getVirtualPrice();
  }

  // --- Trigger condition ---
  /**
   * @dev Checks the yVault pricePerShare
   */
  function checkTriggerCondition() internal override returns (bool) {
    // Read this blocks share price and virtual price
    uint256 _currentVirtualPrice = saddle.getVirtualPrice();

    // Check trigger conditions. We could check one at a time and return as soon as one is true, but it is convenient
    // to have the data that caused the trigger saved into the state, so we don't do that
    bool _statusVirtualPrice = _currentVirtualPrice < ((lastVirtualPrice * virtualPriceTol) / scale);
    bool _statusBalances = checkSaddleBalances();

    // Save the new data
    lastVirtualPrice = _currentVirtualPrice;

    // Return status
    return _statusVirtualPrice || _statusBalances;
  }

  /**
   * @dev Checks if the Saddle internal balances are significantly lower than the true balances
   * @return True if balances are out of tolerance and trigger should be toggled
   */
  function checkSaddleBalances() internal view returns (bool) {
    return
      (token0.balanceOf(address(saddle)) < ((saddle.getTokenBalance(0) * balanceTol) / scale)) ||
      (token1.balanceOf(address(saddle)) < ((saddle.getTokenBalance(1) * balanceTol) / scale)) ||
      (token2.balanceOf(address(saddle)) < ((saddle.getTokenBalance(2) * balanceTol) / scale));
  }
}
