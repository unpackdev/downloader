// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IAngleRouter {
  /// @notice Wrapper built on top of the `_mint` method to mint stablecoins
  /// @param user Address to send the stablecoins to
  /// @param amount Amount of collateral to use for the mint
  /// @param minStableAmount Minimum stablecoin minted for the tx not to revert
  /// @param stablecoin Address of the stablecoin to mint
  /// @param collateral Collateral to mint from
  function mint(
    address user,
    uint256 amount,
    uint256 minStableAmount,
    address stablecoin,
    address collateral
  ) external;

  /// @notice Wrapper built on top of the `_burn` method to burn stablecoins
  /// @param dest Address to send the collateral to
  /// @param amount Amount of stablecoins to use for the burn
  /// @param minCollatAmount Minimum collateral amount received for the tx not to revert
  /// @param stablecoin Address of the stablecoin to mint
  /// @param collateral Collateral to mint from
  function burn(
    address dest,
    uint256 amount,
    uint256 minCollatAmount,
    address stablecoin,
    address collateral
  ) external;
}
