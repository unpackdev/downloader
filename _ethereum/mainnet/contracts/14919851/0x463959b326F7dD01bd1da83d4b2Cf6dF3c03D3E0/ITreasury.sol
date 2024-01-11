// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ITreasury {

  function isSupportedAsset(address token) external view returns (bool);
  function assetReserveDetails(address token) external view returns (uint256 price, uint256 reserves, uint256 totalReserves, uint256 assetRatioPoints);
  function mint(uint256 amount, address token) external returns (address vault);
  function getVault(address token) external view returns (address);

}
