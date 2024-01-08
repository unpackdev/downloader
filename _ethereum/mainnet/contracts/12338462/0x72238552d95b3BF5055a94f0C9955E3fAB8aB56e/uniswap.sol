//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

interface UniSushiSwap {
	function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
	function addLiquidity(address tokenA,address tokenB,uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin,address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
	function swapExactTokensForTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external returns (uint[] memory amounts);
	function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
}

interface IUniswapV2Callee {
  function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}