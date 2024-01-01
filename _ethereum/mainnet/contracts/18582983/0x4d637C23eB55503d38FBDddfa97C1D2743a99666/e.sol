// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20.sol";


contract MoflixGroup is ERC20 {
    constructor( uint256 totalSupply_) ERC20("Moflix Group", "Moflix") {
        _mint(msg.sender, totalSupply_);
    }
}