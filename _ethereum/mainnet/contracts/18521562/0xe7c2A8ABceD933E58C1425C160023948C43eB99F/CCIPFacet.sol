// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Client.sol";
import "./IRouterClient.sol";

import "./LibAppStorage.sol";
import "./LibCCIP.sol";
import "./LibTokenManager.sol";

import "./Test.sol";

contract CCIPFacet is Modifiers {
    uint8 private constant SEND_TOKEN_ACTION = 1;

    /**
     * @notice Receives a CCIP (Cross-Chain Interoperability Protocol) message and triggers the appropriate action.
     * @dev This function decodes the CCIP message and based on the action, triggers the corresponding functionality.
     * Currently, it supports the SEND_TOKEN_ACTION which triggers the sendToken functionality.
     * @param any2EvmMessage The CCIP message received.
     */
    function ccipReceive(Client.Any2EVMMessage calldata any2EvmMessage) external {
        (, bytes memory actionPayload) = LibCCIP.handleReceiveMessage(any2EvmMessage);
        (uint8 action, bytes memory payload) = abi.decode(actionPayload, (uint8, bytes));

        if (action == SEND_TOKEN_ACTION) {
            LibTokenManager.sendToken(payload);
        }
    }
}
