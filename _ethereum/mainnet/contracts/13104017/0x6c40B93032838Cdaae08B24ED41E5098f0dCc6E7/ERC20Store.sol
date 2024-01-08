// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* STORAGE LAYOUT */

struct ERC20Store {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
    uint256 total;
    string named;
    string symboled;
    uint8 decimaled;
}