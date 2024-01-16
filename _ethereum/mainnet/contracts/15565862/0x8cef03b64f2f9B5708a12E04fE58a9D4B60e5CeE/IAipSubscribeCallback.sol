// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAipSubscribeCallback {
    function aipSubscribeCallback(uint256 amount, bytes calldata data) external;
}
