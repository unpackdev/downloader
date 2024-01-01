// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20.sol";


contract Grok30 is ERC20 {
    constructor( uint256 totalSupply_) ERC20("Grok3.0", "Grok3.0") {
        _mint(msg.sender, totalSupply_);
    }
}