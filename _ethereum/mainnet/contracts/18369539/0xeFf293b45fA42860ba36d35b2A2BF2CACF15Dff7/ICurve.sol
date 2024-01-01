// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./PermitParams.sol";

interface ICurve {
  error DeadlineExpired();
  error InsufficientOutputAmount();
  error EthTransferFailed();

  struct ExactInputSingleParams {
    uint256 amountIn;
    uint256 amountOut;
    address recipient;
    address pool;
    uint16 feeBps;
    uint16 slippageBps;
    address partner;
    address tokenIn;
    address tokenOut;
    uint48 deadline;
    uint8 tokenIndexIn;
    uint8 tokenIndexOut;
    uint8 kind;
    bool underlying;
  }

  function curveExactInputSingle(
    ExactInputSingleParams memory params,
    PermitParams calldata permit
  ) external payable returns (uint256 amountOut);
}
