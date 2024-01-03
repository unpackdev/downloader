// SPDX-License-Identifier: MIT

pragma solidity >0.6.0;

import "./ERC20.sol";


contract ERC20Token is ERC20 {
    constructor(string memory name, string memory symbol, uint8 decimal, uint256 initialBalance) ERC20(name, symbol) {
        _setupDecimals(decimal);
        _mint(msg.sender, initialBalance);
    }
}