// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

struct Order {
    int24 tickThreshold;
    bool ejectAbove;
    address payable receiver;
    address owner;
    uint256 maxFeeAmount;
    uint256 startTime;
    bool ejectAtExpiry;
}

struct OrderParams {
    uint256 tokenId;
    int24 tickThreshold;
    bool ejectAbove;
    address payable receiver;
    address feeToken;
    address resolver;
    uint256 maxFeeAmount;
    bool ejectAtExpiry;
}
