/**
 * @title IReceiver
 * @notice Receives messages on destination chain and forwards them to IMessageDestinationHandler
 */
interface IMessageTransmitter {
    /**
     * @notice Receives an incoming message, validating the header and passing
     * the body to application-specific handler.
     * @param message The message raw bytes
     * @param signature The message signature
     * @return success bool, true if successful
     */
    function receiveMessage(
        bytes calldata message,
        bytes calldata signature
    ) external returns (bool success);
}
