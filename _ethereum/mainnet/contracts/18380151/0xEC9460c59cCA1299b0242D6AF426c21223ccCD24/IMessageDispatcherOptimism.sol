// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "./IMessageDispatcher.sol";

/**
 * @title ERC-5164: Cross-Chain Execution Standard
 * @dev IMessageDispatcher interface extended to support a custom gas limit for Optimism.
 * @dev See https://eips.ethereum.org/EIPS/eip-5164
 */
interface IMessageDispatcherOptimism is IMessageDispatcher {
  /**
   * @notice Dispatch and process a message to the receiving chain.
   * @dev Must compute and return an ID uniquely identifying the message.
   * @dev Must emit the `MessageDispatched` event when successfully dispatched.
   * @param _toChainId ID of the receiving chain
   * @param _to Address on the receiving chain that will receive `data`
   * @param _data Data dispatched to the receiving chain
   * @param _gasLimit Gas limit at which the message will be executed on Optimism
   * @return bytes32 ID uniquely identifying the message
   */
  function dispatchMessageWithGasLimit(
    uint256 _toChainId,
    address _to,
    bytes calldata _data,
    uint32 _gasLimit
  ) external returns (bytes32);

  /**
   * @notice Dispatch and process `messages` to the receiving chain.
   * @dev Must compute and return an ID uniquely identifying the `messages`.
   * @dev Must emit the `MessageBatchDispatched` event when successfully dispatched.
   * @param _toChainId ID of the receiving chain
   * @param _messages Array of Message dispatched
   * @param _gasLimit Gas limit at which the message will be executed on Optimism
   * @return bytes32 ID uniquely identifying the `messages`
   */
  function dispatchMessageWithGasLimitBatch(
    uint256 _toChainId,
    MessageLib.Message[] calldata _messages,
    uint32 _gasLimit
  ) external returns (bytes32);
}
