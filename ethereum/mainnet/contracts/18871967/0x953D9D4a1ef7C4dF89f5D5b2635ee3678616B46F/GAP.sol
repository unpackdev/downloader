// SPDX-License-Identifier: MIT
/**
WELCOME TO GAP
*/



pragma solidity ^0.8.20;

import "./ERC20.sol";

contract GAP is ERC20 {
    constructor() ERC20("GAP", "GAP") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}