// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// user account
struct Account {
    uint feeDiscount;
    mapping(address => uint) balances;
}

struct Service {
    bool terminated;
    address token;
    address buyer;
    address seller;
    uint security;
    uint lastConsume;
}