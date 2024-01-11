// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMessageHandler {

    // Handles the given message from the other bridge
    // Admin only.
    function handleMessage(bytes calldata _data) external;
}