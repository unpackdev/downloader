// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface StructInterface {
    struct BridgeData {
        address sendingAsset;
        address receiver;
        uint256 chainId;
    }
}