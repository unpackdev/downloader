// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface CollectInterface {
  function getPriceCumulative() external view returns (int256, uint64);
}