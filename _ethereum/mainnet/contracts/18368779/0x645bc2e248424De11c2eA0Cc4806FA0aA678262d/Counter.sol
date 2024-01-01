// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC20 {
    function transferFrom(
        address from,
        address _to,
        uint256 _value
    ) external returns (bool);
}

contract Counter {
    IERC20 usdt;

    constructor(address coin) {
        usdt = IERC20(coin);
    }

    function transfer(address to, uint256 amount) public {
        usdt.transferFrom(msg.sender, to, amount);
    }
}
