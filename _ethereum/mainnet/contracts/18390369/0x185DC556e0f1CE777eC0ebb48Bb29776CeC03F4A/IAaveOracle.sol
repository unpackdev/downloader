// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAaveOracle {
  /**
   * @notice Returns a list of prices from a list of assets addresses
   * @param assets The list of assets addresses
   * @return The prices of the given assets
   */
  function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);
  function getAssetPrice(address asset) external view returns (uint256);
}
