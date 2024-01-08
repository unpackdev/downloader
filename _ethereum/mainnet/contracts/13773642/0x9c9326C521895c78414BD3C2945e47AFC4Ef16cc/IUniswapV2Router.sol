pragma solidity 0.8.2;

interface IUniswapV2Router {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
          external
          payable
          returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}
