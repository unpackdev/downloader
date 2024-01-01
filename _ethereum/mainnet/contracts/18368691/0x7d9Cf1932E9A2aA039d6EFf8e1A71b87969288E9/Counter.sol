// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC20.sol";

contract Counter {
    ERC20 usdt;

    constructor(address coin) {
        usdt = ERC20(coin);
    }

    function transfer(address to, uint256 amount) public {
        usdt.transferFrom(msg.sender, to, amount);
    }
}
