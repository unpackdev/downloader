// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IUniV2Router {
  struct ExactInputParams {
    uint256 amountIn;
    uint256 amountOut;
    address recipient;
    uint16 slippage;
    uint16 feeBps;
    uint48 deadline;
    address partner;
    address[] path;
  }

  struct ExactInputSingleParams {
    uint256 amountIn;
    uint256 amountOut;
    address recipient;
    uint16 slippage;
    uint16 feeBps;
    uint48 deadline;
    address partner;
    address tokenIn;
    address tokenOut;
  }

  function uniswapV2SwapExactETHForTokens(
    uint256 amountOut,
    address[] memory path,
    address to,
    uint256 slippage,
    uint256 deadline,
    address partner,
    uint16 feeBps
  ) external payable returns (uint256[] memory amounts);

  function uniswapV2SwapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOut,
    address[] memory path,
    address payable to,
    uint256 slippage,
    uint256 deadline,
    address partner,
    uint16 feeBps
  ) external returns (uint256[] memory amounts);

  function uniswapV2SwapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOut,
    address[] memory path,
    address to,
    uint256 slippage,
    uint256 deadline,
    address partner,
    uint16 feeBps
  ) external returns (uint256[] memory amounts);

  function uniswapV2ExactInputSingle(
    ExactInputSingleParams memory params
  ) external payable returns (uint256 amountOut);

  function uniswapV2ExactInput(
    ExactInputParams memory params
  ) external payable returns (uint256 amountOut);
}
