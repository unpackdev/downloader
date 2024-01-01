// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract X is ERC20 {
    constructor() ERC20("X", "X") {
        _mint(msg.sender, 21 * 10 ** 18);
    }
}