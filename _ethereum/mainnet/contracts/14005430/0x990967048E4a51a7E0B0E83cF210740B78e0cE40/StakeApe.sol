// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

struct StakeApe {
    uint256 tokenId;
    address owner;
    bytes1 state; 
    // N: NoOp, T: Training, M: Match, 
    // L: Available for rent, D: Rented
    uint256 stateDate;
}
