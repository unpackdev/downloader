// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20.sol";


contract Beoble is ERC20 {
    constructor( uint256 totalSupply_) ERC20("Beoble Coin", "Beoble") {
        _mint(msg.sender, totalSupply_);
    }
}