// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ITRACAssets {
  struct Purchases { uint48[] backpacks; uint48[] lockers; }
  function balanceOf(address, uint256) external view returns (uint256);
  function getPurchases(address) external view returns (Purchases memory);
}
