// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct Message {
    address service;
    bytes data;
    uint256 salt;
    uint256 deadline;
}

struct MessageFeeCollector {
    address service;
    bytes data;
    uint256 salt;
    uint256 deadline;
    address feeToken;
}

struct MessageTrackFee {
    address service;
    bytes data;
    uint256 salt;
    uint256 deadline;
    address feeToken;
    bool isFeeCollector;
}

struct MessageRelayContext {
    address service;
    bytes data;
    uint256 salt;
    uint256 deadline;
    address feeToken;
    uint256 fee;
}

struct ExecWithSigs {
    bytes32 correlationId;
    Message msg;
    bytes executorSignerSig;
    bytes checkerSignerSig;
}

struct ExecWithSigsFeeCollector {
    bytes32 correlationId;
    MessageFeeCollector msg;
    bytes executorSignerSig;
    bytes checkerSignerSig;
}

struct ExecWithSigsTrackFee {
    bytes32 correlationId;
    MessageTrackFee msg;
    bytes executorSignerSig;
    bytes checkerSignerSig;
}

struct ExecWithSigsRelayContext {
    bytes32 correlationId;
    MessageRelayContext msg;
    bytes executorSignerSig;
    bytes checkerSignerSig;
}
