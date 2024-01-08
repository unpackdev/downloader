// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface ISwap {
  function swapExactTokenIn(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut) external payable returns (uint256);
}