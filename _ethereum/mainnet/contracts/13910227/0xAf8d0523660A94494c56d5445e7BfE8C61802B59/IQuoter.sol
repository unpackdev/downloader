pragma solidity >=0.6.0 <0.9.0;

interface IQuoter {
  function quoteExactInputSingle(
      address tokenIn,
      address tokenOut,
      uint24 fee,
      uint256 amountIn,
      uint160 sqrtPriceLimitX96
  ) external returns (uint256 amountOut);
}
