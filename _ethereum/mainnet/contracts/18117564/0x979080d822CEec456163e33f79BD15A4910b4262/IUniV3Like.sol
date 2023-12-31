// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IUniV3Like {
  error InsufficienTokensDelivered();
  error DeadlineExpired();
  error InsufficientOutputAmount();
  error EthTransferFailed();
  error IncorrectEthValue();

  struct ExactInputParams {
    uint256 amountIn;
    uint256 amountOut;
    address recipient;
    uint16 slippageBps;
    uint16 feeBps;
    uint48 deadline;
    address partner;
    address[] tokens;
    address[] pools;
  }

  struct ExactInputSingleParams {
    address recipient;
    address partner;
    uint16 feeBps;
    uint16 slippageBps;
    uint256 amountIn;
    uint48 deadline;
    address tokenIn;
    address tokenOut;
    uint256 amountOut;
    address pool;
  }

  function uniswapV3LikeExactInputSingle(
    ExactInputSingleParams memory params
  ) external payable returns (uint256 amountOut);

  function uniswapV3LikeExactInput(
    ExactInputParams memory params
  ) external payable returns (uint256 amountOut);
}
