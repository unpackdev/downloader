pragma solidity 0.8.12;

// Copyright BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0
interface IV3Pool {
  function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut)
    external;

  function getController() external view returns (address);

  function isBound(address t) external view returns (bool);
}
