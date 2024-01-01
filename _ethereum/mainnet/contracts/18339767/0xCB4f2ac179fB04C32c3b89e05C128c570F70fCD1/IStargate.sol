// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./PermitParams.sol";

interface IStargate {
  error InsufficientEthValue();

  struct JumpTokenParams {
    address token;
    uint160 amountIn;
    /**
     * The amount the user was quoted. Used to calculate the minimum acceptable
     * amount of tokens to receive.
     */
    uint160 amountOutExpected;
    address recipient;
    uint16 slippageBps;
    uint16 feeBps;
    uint48 deadline;
    address partner;
    uint16 dstChainId;
    uint8 srcPoolId;
    uint8 dstPoolId;
  }

  struct JumpNativeParams {
    /**
     * The amount in is passed to distinguish the amount to bridge from the fee
     */
    uint160 amountIn;
    /**
     * The amount the user was quoted. Used to calculate the minimum acceptable
     * amount of tokens to receive.
     */
    uint160 amountOutExpected;
    address recipient;
    uint16 slippageBps;
    uint16 feeBps;
    uint48 deadline;
    address partner;
    uint16 dstChainId;
    uint8 srcPoolId;
    uint8 dstPoolId;
  }

  function stargateJumpToken(
    JumpTokenParams calldata params,
    PermitParams calldata permit
  ) external payable;

  function stargateJumpNative(JumpNativeParams calldata params) external payable;
}
