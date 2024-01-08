// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface ILiquidityDex {
  function doSwap(
    uint256 amountIn,
    uint256 minAmountOut,
    address spender,
    address target,
    address[] memory path
  ) external returns (uint256);
}
