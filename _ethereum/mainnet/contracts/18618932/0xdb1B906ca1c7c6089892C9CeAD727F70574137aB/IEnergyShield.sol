// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IEnergyShield {
  error CallFailed();
  error EthTransferFailed();

  struct SingleParams {
    address tokenOut;
    address target;
    bytes data;
    /**
     *
     * When true, the target is expected to deliver the tokens directly to `msg.sender`
     * When false, the target is expected to deliver the tokens to the energy shield
     */
    bool delivers;
  }

  struct MultiParams {
    address tokenOut;
    address[] targets;
    bytes data;
    /**
     * The offsets in data for each target excluding the first, which would be 0
     */
    uint256[] offsets;
    /**
     *
     * When true, the final target is expected to deliver the tokens directly to `msg.sender`
     * When false, the final target is expected to deliver the tokens to the energy shield
     */
    bool delivers;
  }

  function single(SingleParams calldata params) external payable returns (uint256 amountOut);

  function multi(MultiParams calldata params) external payable returns (uint256 amountOut);

  function drain(address token) external;
}
