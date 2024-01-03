// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.6.2;

interface IMasterChef {
  function deposit(uint256 poolId, uint256 amount) external;
  function withdraw(uint256 poolId, uint256 amount) external;
}
