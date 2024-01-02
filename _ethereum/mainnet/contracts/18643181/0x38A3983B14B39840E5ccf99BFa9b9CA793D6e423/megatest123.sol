// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.21;

contract megatest123 {
    uint256 public a;
    uint256 public b;
    constructor(uint256[] memory routers) {
        a=routers[0];
        b=routers[1];
    }
}