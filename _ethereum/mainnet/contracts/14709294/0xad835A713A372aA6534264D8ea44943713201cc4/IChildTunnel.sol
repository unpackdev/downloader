// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChildTunnel {

    // Sends the bytes to the root (L1).
    // Admin only.
    function sendMessageToRoot(bytes calldata _data) external;
}