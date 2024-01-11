// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Relay request with built-in MetaTx support with signature verification on behalf of user
// In case a sponsor (other than user) wants to pay for the tx,
// we will also need to verify sponsor's signature
struct MetaTxRequest {
    uint256 chainId;
    address target;
    bytes data;
    address feeToken;
    uint256 paymentType;
    uint256 maxFee;
    uint256 gas;
    address user;
    address sponsor; // could be same as user
    uint256 sponsorChainId;
    uint256 nonce;
    uint256 deadline;
}

// Similar to MetaTxRequest, but no need to implement user-specific signature verification logic
// Only sponsor signature is verified in order to ensure integrity of fee payments
struct ForwardRequest {
    uint256 chainId;
    address target;
    bytes data;
    address feeToken;
    uint256 paymentType;
    uint256 maxFee;
    uint256 gas;
    address sponsor;
    uint256 sponsorChainId;
    uint256 nonce;
    bool enforceSponsorNonce;
    bool enforceSponsorNonceOrdering;
}
