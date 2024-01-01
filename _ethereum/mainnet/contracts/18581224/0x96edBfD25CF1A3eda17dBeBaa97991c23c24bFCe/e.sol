// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20.sol";


contract HelpGrok is ERC20 {
    constructor( uint256 totalSupply_) ERC20("HelpGrok", "HelpGrok") {
        _mint(msg.sender, totalSupply_);
    }
}