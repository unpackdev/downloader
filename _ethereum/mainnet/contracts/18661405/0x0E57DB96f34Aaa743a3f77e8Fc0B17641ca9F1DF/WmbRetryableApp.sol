// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ExcessivelySafeCall.sol";
import "./WmbApp.sol";

/**
 * @title WmbRetryableApp
 * @dev Abstract contract to be inherited by applications to use Wanchain Message Bridge for send and receive messages and support retry failed transactions
 */
abstract contract WmbRetryableApp is WmbApp {
    // Import the ExcessivelySafeCall library for safe external function calls
    using ExcessivelySafeCall for address;

    // this is the gas reserve for storing the failed message data hash
    // so that we can retry it later
    // this is a constant value that is used in the wmbReceive function
    // and should be updated if the wmbReceive function is updated.
    uint256 public constant RESERVE_GAS_FOR_FAILED_MESSAGE_STORE = 50_000;

    // A mapping of failed messages by their chain ID, address, and message ID, with the value being the message hash
    // This is used to keep track of failed messages in order to retry them later
    // messageId => messageHash
    mapping(bytes32 => bytes32) public failedMessages;

    event MessageFailed(
        bytes32 indexed messageId,
        uint256 indexed fromChainId,
        address indexed from,
        bytes data,
        bytes reason
    );

    event RetryMessageSuccess(
        uint256 indexed fromChainId,
        address indexed from,
        bytes32 indexed messageId,
        bytes32 messageHash
    );

    event MessageDroped(
        bytes32 indexed messageId
    );

    /**
     * @dev Function to receive a WMB message from the WMB Gateway
     * @param data Message data
     * @param messageId Message ID
     * @param fromChainId ID of the chain the message is from
     * @param from Address of the contract the message is from
     */
    function wmbReceive(
        bytes calldata data,
        bytes32 messageId,
        uint256 fromChainId,
        address from
    ) override external {
        // Only the WMB gateway can call this function
        require(msg.sender == wmbGateway, "WmbApp: Only WMB gateway can call this function");
        require(trustedRemotes[fromChainId][from], "WmbApp: Remote is not trusted");
        
        (bool success, bytes memory reason) = address(this).excessivelySafeCall(gasleft() - RESERVE_GAS_FOR_FAILED_MESSAGE_STORE, 150, abi.encodeWithSelector(this.nonblockingWmbReceive.selector, data, messageId, fromChainId, from));
        // try-catch all errors/exceptions
        if (!success) {
            _storeFailedMessage(data, messageId, fromChainId, from, reason);
        }
    }

    // @dev internal use only for safe non-blocking call to _wmbReceive
    function nonblockingWmbReceive(
        bytes calldata data,
        bytes32 messageId,
        uint256 fromChainId,
        address from
    ) public {
        require(msg.sender == address(this), "WmbApp: Only this contract can call this function");
        // call the internal _wmbReceive function, which should be implemented by the inheriting contract
        _wmbReceive(data, messageId, fromChainId, from);
    }

    /**
     * @notice Retry a failed message by resending the same data
     * @param data The data of the failed message
     * @param messageId The ID of the failed message
     * @param fromChainId The ID of the source chain
     * @param from The address of the source contract
     */
    function retryMessage(
        bytes calldata data,
        bytes32 messageId,
        uint256 fromChainId,
        address from
    ) public virtual {
        // assert there is message to retry
        bytes32 messageHash = failedMessages[messageId];
        require(messageHash != bytes32(0), "WmbApp: no stored message");
        require(keccak256(abi.encodePacked(data, messageId, fromChainId, from)) == messageHash, "WmbApp: invalid message data");
        // clear the stored message
        delete failedMessages[messageId];
        // execute the message. revert if it fails again
        _wmbReceive(data, messageId, fromChainId, from);
        emit RetryMessageSuccess(fromChainId, from, messageId, messageHash);
    }

    /**
     * @dev Stores the failed message in the `failedMessages` mapping and emits a `MessageFailed` event
     * @param data The data of the failed message
     * @param messageId The ID of the failed message
     * @param fromChainId The ID of the chain the message was sent from
     * @param from The address the message was sent from
     * @param _reason The reason why the message failed
     */
    function _storeFailedMessage(
        bytes calldata data,
        bytes32 messageId,
        uint256 fromChainId,
        address from,
        bytes memory _reason
    ) internal virtual {
        failedMessages[messageId] = keccak256(abi.encodePacked(data, messageId, fromChainId, from));
        emit MessageFailed(messageId, fromChainId, from, data, _reason);
    }

    /**
     * @notice Drop a failed message by messageId
     * @param messageId The ID of the failed message
     */
    function _dropMessage(
        bytes32 messageId
    ) internal virtual {
        // clear the stored message
        delete failedMessages[messageId];
        emit MessageDroped(messageId);
    }
}
