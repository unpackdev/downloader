// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./ERC20.sol";
import "./Ownable.sol";

contract NEPT is ERC20, Ownable {
    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) 
    ERC20(_name, _symbol) {
        _mint(msg.sender, _initialSupply);
    }
}