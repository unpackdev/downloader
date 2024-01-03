// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IPriceOracle {
  function getAssetPrice(address asset) external view returns (uint256);
}
