// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface BVaultV2 {
  function getPoolTokens(
    bytes32 poolId
  )
    external
    view
    returns (address[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);
}
