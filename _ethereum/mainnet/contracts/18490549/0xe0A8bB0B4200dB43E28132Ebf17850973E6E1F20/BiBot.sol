// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract BIBOT is ERC20 {
    constructor(uint256 amount) ERC20("BIBOT", "BBT") {
        _mint(msg.sender, amount);
    }
}