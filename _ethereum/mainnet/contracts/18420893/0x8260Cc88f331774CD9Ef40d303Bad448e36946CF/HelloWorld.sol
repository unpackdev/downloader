// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract HelloWorld is ERC20 {
    constructor() ERC20("HelloWorld", "1024") {
        _mint(msg.sender, 1024 * 10 ** decimals());
    }
}
