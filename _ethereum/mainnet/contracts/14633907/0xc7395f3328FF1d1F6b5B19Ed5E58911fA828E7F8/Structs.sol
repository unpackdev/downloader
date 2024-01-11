// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct TransferData {
    address fromToken;
    address toToken;
    address fromAddress;
    address toAddress;
    uint256 amount;
    string internalTxId;
}
