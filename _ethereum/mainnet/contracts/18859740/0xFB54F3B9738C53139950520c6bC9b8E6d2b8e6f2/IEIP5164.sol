// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// EIP-5164 defines a cross-chain execution interface for EVM-based blockchains. 
// Implementations of this specification will allow contracts on one chain to call contracts on another by sending a cross-chain message.
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-5164.md

struct Message {
    address to;
    bytes data;
}

interface MessageDispatcher {
  event MessageDispatched(
    bytes32 indexed messageId,
    address indexed from,
    uint256 indexed toChainId,
    address to,
    bytes data
  );

  event MessageBatchDispatched(
    bytes32 indexed messageId,
    address indexed from,
    uint256 indexed toChainId,
    Message[] messages
  );
}

interface SingleMessageDispatcher is MessageDispatcher {
    /**
     * @notice Sends a message to a specified chain and address with the given data.
     * @dev This function is used to dispatch a message to a specified chain and address with the given data.
     * @param toChainId The chain ID of the destination chain.
     * @param to The address of the destination contract on the destination chain.
     * @param data The data to be sent to the destination contract.
     * @return messageId A unique identifier for the dispatched message.
     */ 
    function dispatchMessage(uint256 toChainId, address to, bytes calldata data) external payable returns (bytes32 messageId);
}

interface BatchedMessageDispatcher is MessageDispatcher {
    /**
     * @notice Sends a batch of messages to a specified chain.
     * @dev This function is used to dispatch a batch of messages to a specified chain and returns a unique identifier for the dispatched batch.
     * @param toChainId The chain ID of the destination chain.
     * @param messages An array of Message struct objects containing the destination addresses and data to be sent to each destination contract.
     * @return messageId A unique identifier for the dispatched batch.
     */ 
    function dispatchMessageBatch(uint256 toChainId, Message[] calldata messages) external payable returns (bytes32 messageId);
}

/**
 * MessageExecutor
 *
 * MessageExecutors MUST append the ABI-packed (messageId, fromChainId, from) to the calldata for each message being executed.
 *
 * to: The address of the contract to call.
 * data: The data to cross-chain.
 * messageId: The unique identifier of the message being executed.
 * fromChainId: The ID of the chain the message originated from.
 * from: The address of the sender of the message.
 * to.call(abi.encodePacked(data, messageId, fromChainId, from));
 */
interface MessageExecutor {
    error MessageIdAlreadyExecuted(
        bytes32 messageId
    );

    error MessageFailure(
        bytes32 messageId,
        bytes errorData
    );

    error MessageBatchFailure(
        bytes32 messageId,
        uint256 messageIndex,
        bytes errorData
    );

    event MessageIdExecuted(
        uint256 indexed fromChainId,
        bytes32 indexed messageId
    );
}

interface IEIP5164 is SingleMessageDispatcher, BatchedMessageDispatcher, MessageExecutor {}
