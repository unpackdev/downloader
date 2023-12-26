// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface PoppetStructs {
    struct ThreadConfig {
        // 256 bits available
        uint80 publicMintPrice; // 80
        uint80 signedMintPrice; // 160
        uint16 maxTokenId; // 176
        uint40 endTimestamp; // 216
        uint16 currentThreadId; // 232
        uint24 threadSeed; // 256
    }
}
