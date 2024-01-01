// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./LibAppStorage.sol";
import "./LibCCIP.sol";
import "./ERC721.sol";

contract FishFacet is Modifiers {
    error InvalidPayment(uint256 want, uint256 have);

    uint8 private constant NEW_FISH = 1;

    event NewFish(address indexed sender, bytes32 messageId, bytes payload);

    /**
     * @notice Allows a user to perform a fishing action.
     * @dev This function checks the validity of the quantity and payment, encodes the data, sends a message, and emits the NewFish event.
     * It reverts if the provided quantity is invalid or if the sent payment doesn't match the expected value.
     * @dev if all is good, send the payload to the manager contract on Polygon using Chainlink Cross-Chain Interoperability Protocol (CCIP).
     * The NEW_FISH constant is used to route the transaction to the right handler on the manager contract (cf polygon/facets/ManagerCCIPFacet.sol)
     */
    function fish() external payable {
        if (msg.value != s.price) {
            revert InvalidPayment({want: s.price, have: msg.value});
        }

        bytes memory fishPayload = abi.encode(msg.sender);
        bytes memory actionPayload = abi.encode(NEW_FISH, fishPayload);

        bytes32 messageId = LibCCIP.sendMessage(actionPayload, 2_000_000);

        emit NewFish(msg.sender, messageId, fishPayload);
    }
}
