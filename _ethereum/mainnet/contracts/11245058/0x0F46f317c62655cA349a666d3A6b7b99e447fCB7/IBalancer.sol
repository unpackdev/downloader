//SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.4;

interface IBalancerPool {
  function swapExactAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    address tokenOut,
    uint256 minAmountOut,
    uint256 maxPrice
  ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);
}
