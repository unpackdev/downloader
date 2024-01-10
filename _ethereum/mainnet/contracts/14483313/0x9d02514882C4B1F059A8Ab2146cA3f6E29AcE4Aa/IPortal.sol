// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPortal {
    function sendMessage(bytes calldata message_) external;
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
    function receiveMessage(bytes memory data) external;
}