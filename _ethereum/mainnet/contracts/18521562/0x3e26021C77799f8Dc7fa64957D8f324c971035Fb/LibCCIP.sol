// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Client.sol";

import "./LibAppStorage.sol";

library LibCCIP {
    // Custom errors to provide more descriptive revert messages.
    // Used to make sure contract has enough balance.
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
    error NotTheJunkyard(uint64 selector, address sender);
    error InvalidRouter(address router);

    // Event emitted when a message is sent to another chain.
    // The chain selector of the destination chain.
    // The address of the receiver on the destination chain.
    // The text being sent.
    // the token address used to pay CCIP fees.
    // The fees paid for sending the CCIP message.
    event MessageSent( // The unique ID of the CCIP message.
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        bytes payload,
        address feeToken,
        uint256 fees
    );
    // Event emitted when a message is received from another chain.
    event MessageReceived( // The unique ID of the CCIP message.
        // The chain selector of the source chain.
        // The address of the sender from the source chain.
        // The text that was received.
    bytes32 indexed messageId, uint64 indexed sourceChainSelector, address sender, bytes payload);

    /**
     * @notice Sends data to the receiver on the destination chain.
     * @dev Assumes the contract has sufficient LINK or ETH to pay the fees.
     * @param payload The action payload.
     * @param gasLimit The gas limit for sending the message.
     * @return messageId The ID of the message sent.
     */
    function sendMessage(bytes memory payload, uint256 gasLimit) internal returns (bytes32 messageId) {
        AppStorage storage s = LibAppStorage.appStorage();
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(s.CCIPReceiver), // ABI-encoded receiver address
            data: payload, // Payload
            tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array indicating no tokens are being sent
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit and non-strict sequencing mode
                Client.EVMExtraArgsV1({gasLimit: gasLimit, strict: false})
                ),
            // Set the feeToken  address, indicating LINK will be used for fees
            feeToken: s.linkTokenAddr
        });

        // Get the fee required to send the message
        uint256 fees = s.CCIPRouter.getFee(s.CCIPdestinationChainSelector, evm2AnyMessage);
        if (fees > address(this).balance) {
            revert NotEnoughBalance(address(this).balance, fees);
        }

        // Send the message through the router and store the returned message ID
        messageId = s.CCIPRouter.ccipSend{value: fees}(s.CCIPdestinationChainSelector, evm2AnyMessage);

        // Emit an event with message details
        emit MessageSent(messageId, s.CCIPdestinationChainSelector, s.CCIPReceiver, payload, s.linkTokenAddr, fees);

        // Return the message ID
        return messageId;
    }

    /**
     * @notice Handles the reception of a CCIP message.
     * @param any2EvmMessage The received CCIP message.
     * @return sender The sender address of the message.
     * @return payload The payload of the message.
     */
    function handleReceiveMessage(Client.Any2EVMMessage memory any2EvmMessage)
        internal
        returns (address sender, bytes memory payload)
    {
        AppStorage storage s = LibAppStorage.appStorage();

        // abi-decoding of the sender address,
        sender = abi.decode(any2EvmMessage.sender, (address));

        if (msg.sender != address(s.CCIPRouter)) {
            revert InvalidRouter(msg.sender);
        }
        if (any2EvmMessage.sourceChainSelector != s.CCIPdestinationChainSelector || sender != s.CCIPReceiver) {
            revert NotTheJunkyard(any2EvmMessage.sourceChainSelector, sender);
        }

        emit MessageReceived(any2EvmMessage.messageId, any2EvmMessage.sourceChainSelector, sender, any2EvmMessage.data);

        return (sender, any2EvmMessage.data);
    }
}
