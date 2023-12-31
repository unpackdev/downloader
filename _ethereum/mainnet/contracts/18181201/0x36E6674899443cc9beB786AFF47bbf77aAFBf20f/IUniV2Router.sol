// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./PermitParams.sol";

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

  function uniswapV2ExactInputSingle(
    ExactInputSingleParams memory params,
    PermitParams calldata permit
  ) external payable returns (uint256 amountOut);

  function uniswapV2ExactInput(
    ExactInputParams memory params,
    PermitParams calldata permit
  ) external payable returns (uint256 amountOut);
}
