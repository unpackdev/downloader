// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IMooniswap {
  function getBalanceForRemoval(address token) external view returns(uint256);
  function token0() external view returns(address);
  function token1() external view returns(address);
  function totalSupply() external view returns(uint256);
}
