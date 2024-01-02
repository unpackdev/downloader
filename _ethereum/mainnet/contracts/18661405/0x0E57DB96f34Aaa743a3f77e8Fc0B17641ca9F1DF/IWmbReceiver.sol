// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IWmbReceiver
 * @dev Interface for contracts that can receive messages from the Wanchain Message Bridge (WMB).
 */
interface IWmbReceiver {
    /**
     * @dev Handles a message received from the WMB network
     * @param data The data contained within the message
     * @param messageId The unique identifier of the message
     * @param fromChainId The ID of the chain that sent the message
     * @param from The address of the contract that sent the message
     * 
     * This interface follows the EIP-5164 standard.
     */
    function wmbReceive(
        bytes calldata data,
        bytes32 messageId,
        uint256 fromChainId,
        address from
    ) external;
}
