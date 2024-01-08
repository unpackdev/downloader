// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./AbstractPool.sol";

abstract contract BPool is AbstractPool {
  function finalize() external virtual;
  function bind(address token, uint balance, uint denorm) external virtual;
  function rebind(address token, uint balance, uint denorm) external virtual;
  function unbind(address token) external virtual;
  function isBound(address t) external view virtual returns (bool);
  function getCurrentTokens() external view virtual returns (address[] memory);
  function getFinalTokens() external view virtual returns(address[] memory);
  function getBalance(address token) external view virtual returns (uint);
  function getSpotPrice(address tokenIn, address tokenOut) external view virtual returns (uint spotPrice);
  function getSpotPriceSansFee(address tokenIn, address tokenOut) external view virtual returns (uint spotPrice);
  function getNormalizedWeight(address token) external view virtual returns (uint);
  function isFinalized() external view virtual returns (bool);
  function swapExactAmountIn(address tokenIn, uint tokenAmountIn, address tokenOut, uint minAmountOut, uint maxPrice) external virtual returns (uint tokenAmountOut, uint spotPriceAfter);
  function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external virtual;
  function swapExactAmountOut(address tokenIn, uint maxAmountIn, address tokenOut, uint tokenAmountOut, uint maxPrice) external virtual;
  function joinswapExternAmountIn(address tokenIn, uint tokenAmountIn, uint minPoolAmountOut) external virtual;
  function joinswapPoolAmountOut(address tokenIn, uint poolAmountOut, uint maxAmountIn) external virtual;
  function exitswapPoolAmountIn(address tokenOut, uint poolAmountIn, uint minAmountOut) external virtual;
  function exitswapExternAmountOut(address tokenOut, uint tokenAmountOut, uint maxPoolAmountIn) external virtual;
  function getNumTokens() external virtual view returns(uint);
  function getDenormalizedWeight(address token) external virtual view returns (uint);
  function getSwapFee() external virtual view returns(uint);
  function getController() external virtual view returns(address);
}