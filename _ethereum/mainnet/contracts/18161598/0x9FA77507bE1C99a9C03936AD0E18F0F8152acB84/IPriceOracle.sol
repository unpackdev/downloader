// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IPriceOracle {
  function getAssetPrice(address _asset) external view returns (uint256);
}
