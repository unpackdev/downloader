pragma solidity ^0.6.0;

interface IUniswapV2Oracle {
  function current(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut);
}