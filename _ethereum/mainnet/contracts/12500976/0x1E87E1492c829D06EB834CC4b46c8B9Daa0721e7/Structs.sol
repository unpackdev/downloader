// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

struct Proposal {
    address tokenTo;
    address from;
    address to;
    uint256 amount;
    uint256 count;
    string txid;
    bool isFinished;
    bool isExist;
    mapping(address => bool) isVoted;
}
