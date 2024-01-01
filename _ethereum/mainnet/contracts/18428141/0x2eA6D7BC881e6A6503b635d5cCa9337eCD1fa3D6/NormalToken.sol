// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract Token is ERC20 {
    constructor(string memory name, string memory symbol, uint256 amount,address receiveAddr) ERC20(name, symbol) {
        _mint(receiveAddr, amount);
    }
}