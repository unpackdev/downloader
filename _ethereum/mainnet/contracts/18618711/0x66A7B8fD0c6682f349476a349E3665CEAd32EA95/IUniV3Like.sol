// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IAllowanceTransfer.sol";
import "./PermitParams.sol";
import "./ILibStarVault.sol";
import "./ILibUniV3Like.sol";
import "./ILibWarp.sol";

interface IUniV3Like is ILibStarVault, ILibUniV3Like, ILibWarp {
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
    ExactInputSingleParams calldata params
  ) external payable returns (uint256 amountOut);

  function uniswapV3LikeExactInputSinglePermit(
    ExactInputSingleParams calldata params,
    PermitParams calldata permit
  ) external returns (uint256 amountOut);

  function uniswapV3LikeExactInput(
    ExactInputParams calldata params
  ) external payable returns (uint256 amountOut);

  function uniswapV3LikeExactInputPermit(
    ExactInputParams calldata params,
    PermitParams calldata permit
  ) external returns (uint256 amountOut);
}
