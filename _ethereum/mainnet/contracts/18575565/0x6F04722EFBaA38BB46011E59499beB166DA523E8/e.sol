// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20.sol";


contract DogeAI20 is ERC20 {
    constructor( uint256 totalSupply_) ERC20("DogeAI2.0", "DogeAI2.0") {
        _mint(msg.sender, totalSupply_);
    }
}