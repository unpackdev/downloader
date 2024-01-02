// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./PermitParams.sol";

interface IStateless {
  error DeadlineExpired();
  error InsufficientOutputAmount();
  error EthTransferFailed();
  error IncorrectEthValue();

  struct SingleParams {
    uint256 amountIn;
    uint256 amountOut;
    address recipient;
    uint16 slippageBps;
    uint16 feeBps;
    address partner;
    address tokenIn;
    address tokenOut;
    uint48 deadline;
    address target;
    bytes data;
    /**
     * When true, tokens will be transferred to the target before the call.
     * When false, tokens will be transferred to the energy shield before the call.
     */
    bool push;
    /**
     *
     * When true, the target is expected to deliver the tokens directly to `msg.sender`
     * When false, the target is expected to deliver the tokens to the energy shield
     */
    bool delivers;
  }

  struct MultiParams {
    uint256 amountIn;
    uint256 amountOut;
    address recipient;
    uint16 slippageBps;
    uint16 feeBps;
    address partner;
    address tokenIn;
    address tokenOut;
    uint48 deadline;
    address[] targets;
    bytes data;
    /**
     * The offsets in data for each target excluding the first, which would be 0
     */
    uint256[] offsets;
    /**
     * When true, tokens will be transferred to the first target before the first call.
     * When false, tokens will be transferred to the energy shield before the first call.
     */
    bool push;
    /**
     *
     * When true, the target is expected to deliver the tokens directly to `msg.sender`
     * When false, the target is expected to deliver the tokens to the energy shield
     */
    bool delivers;
  }

  function energyShieldAddress() external view returns (address energyShield);

  function warpStatelessSingle(
    SingleParams calldata params
  ) external payable returns (uint256 amountOut);

  function warpStatelessSinglePermit(
    SingleParams calldata params,
    PermitParams calldata permit
  ) external returns (uint256 amountOut);

  function warpStatelessMulti(
    MultiParams calldata params
  ) external payable returns (uint256 amountOut);

  function warpStatelessMultiPermit(
    MultiParams calldata params,
    PermitParams calldata permit
  ) external returns (uint256 amountOut);
}
