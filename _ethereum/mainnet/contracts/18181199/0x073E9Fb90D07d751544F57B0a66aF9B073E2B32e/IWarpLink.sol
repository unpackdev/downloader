// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./PermitParams.sol";

interface IWarpLink {
  error UnhandledCommand();
  error IncorrectEthValue();
  error InsufficientOutputAmount();
  error InsufficientTokensDelivered();
  error UnexpectedTokenForWrap();
  error UnexpectedTokenForUnwrap();
  error UnexpectedTokenOut();
  error InsufficientAmountRemaining();
  error NotEnoughParts();
  error InconsistentPartTokenOut();
  error InconsistentPartPayerOut();
  error UnexpectedValueAndTokenCombination();
  error UnexpectedPayerForWrap();
  error EthNotSupportedForWarp();
  error DeadlineExpired();

  struct Params {
    address partner;
    uint16 feeBps;
    /**
     * How much below `amountOut` the user will accept
     */
    uint16 slippageBps;
    address recipient;
    address tokenIn;
    address tokenOut;
    uint256 amountIn;
    /**
     * The amount the user was quoted
     */
    uint256 amountOut;
    uint48 deadline;
    bytes commands;
  }

  function warpLinkEngage(Params memory params, PermitParams calldata permit) external payable;

  function commandTypeWrap() external pure returns (uint256);

  function commandTypeUnwrap() external pure returns (uint256);

  function commandTypeWarpUniV2LikeExactInputSingle() external pure returns (uint256);

  function commandTypeSplit() external pure returns (uint256);

  function commandTypeWarpUniV2LikeExactInput() external pure returns (uint256);

  function commandTypeWarpUniV3LikeExactInputSingle() external pure returns (uint256);

  function commandTypeWarpUniV3LikeExactInput() external pure returns (uint256);

  function commandTypeWarpCurveExactInputSingle() external pure returns (uint256);
}
