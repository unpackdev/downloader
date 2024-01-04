// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface IBPool {
  function swapExactAmountIn (
    address tokenIn,
    uint tokenAmountIn,
    address tokenOut,
    uint minAmountOut,
    uint maxPrice
  ) external returns (uint tokenAmountOut, uint spotPriceAfter);
}
