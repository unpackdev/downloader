// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IPoolManager {
  struct PoolInfo {
    address pool;
    uint256 percentage;
  }

  function stakingToken() external view returns (address);

  function getAllPools() external view returns (PoolInfo[] memory);
}
