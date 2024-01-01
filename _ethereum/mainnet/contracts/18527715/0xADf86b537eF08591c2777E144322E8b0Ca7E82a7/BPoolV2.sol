// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface BPoolV2 {
  function getNormalizedWeights() external view returns (uint256[] memory);

  function totalSupply() external view returns (uint256);

  function getPoolId() external view returns (bytes32);
}
