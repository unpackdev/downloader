// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB) external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address);
}
