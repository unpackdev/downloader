// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRootTunnel {

    // Sends the bytes to the child (L2).
    // Admin only.
    function sendMessageToChild(bytes calldata _data) external;
}