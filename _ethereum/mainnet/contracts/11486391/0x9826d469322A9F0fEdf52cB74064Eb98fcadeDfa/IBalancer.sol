// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

interface IBalancer {
  function swapExactAmountOut(
    address tokenIn,
    uint256 maxAmountIn,
    address tokenOut,
    uint256 tokenAmountOut,
    uint256 maxPrice
  ) external returns (uint256 tokenAmountIn, uint256 spotPriceAfter);

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
  ) external view returns (uint256);

  function getSpotPrice(address tokenIn, address tokenOut)
    external
    view
    returns (uint256);

  function getNormalizedWeight(address token) external view returns (uint256);

  function getSwapFee() external view returns (uint256);

  function getCurrentTokens() external view returns (address[] memory);

  function drip(address) external;
}
