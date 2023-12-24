// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "./MessageLib.sol";

/**
 * @title ERC-5164: Cross-Chain Execution Standard
 * @dev See https://eips.ethereum.org/EIPS/eip-5164
 */
interface IMessageDispatcher {
  /**
   * @notice Emitted when a message has successfully been dispatched to the executor chain.
   * @param messageId ID uniquely identifying the message
   * @param from Address that dispatched the message
   * @param toChainId ID of the chain receiving the message
   * @param to Address that will receive the message
   * @param data Data that was dispatched
   */
  event MessageDispatched(
    bytes32 indexed messageId,
    address indexed from,
    uint256 indexed toChainId,
    address to,
    bytes data
  );

  /**
   * @notice Dispatch a message to the receiving chain.
   * @dev Must compute and return an ID uniquely identifying the message.
   * @dev Must emit the `MessageDispatched` event when successfully dispatched.
   * @param toChainId ID of the receiving chain
   * @param to Address on the receiving chain that will receive `data`
   * @param data Data dispatched to the receiving chain
   * @return bytes32 ID uniquely identifying the message
   */
  function dispatchMessage(
    uint256 toChainId,
    address to,
    bytes calldata data
  ) external returns (bytes32);

  /**
   * @notice Retrieves address of the MessageExecutor contract on the receiving chain.
   * @dev Must revert if `toChainId` is not supported.
   * @param toChainId ID of the chain with which MessageDispatcher is communicating
   * @return address MessageExecutor contract address
   */
  function getMessageExecutorAddress(uint256 toChainId) external returns (address);
}
