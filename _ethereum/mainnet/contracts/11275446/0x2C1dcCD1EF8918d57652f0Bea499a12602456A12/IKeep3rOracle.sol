pragma solidity ^0.6.0;

interface IKeep3rOracle {
  function current(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut);
  function rVolHourly(address tokenIn, address tokenOut, uint points) external view returns (uint);
}