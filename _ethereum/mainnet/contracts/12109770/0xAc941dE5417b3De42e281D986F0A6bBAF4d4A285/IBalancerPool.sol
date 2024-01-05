// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IBalancerPool {
  function swapExactAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    address tokenOut,
    uint256 minAmountOut,
    uint256 maxPrice
  ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

  function calcOutGivenIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountIn,
    uint256 swapFee
  ) external view returns (uint256 tokenAmountOut);

  function getBalance(address token) external view returns (uint256 balance);

  function getDenormalizedWeight(address token) external view returns (uint256 weight);

  function getSwapFee() external view returns (uint256 fee);
}
