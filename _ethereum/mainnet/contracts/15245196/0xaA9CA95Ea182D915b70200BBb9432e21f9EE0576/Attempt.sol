//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

struct Attempt {
    bytes32 hash;
    uint256 startTokenId;
    uint8 genderId;
    uint8 classId;
    uint8 itemId;
}