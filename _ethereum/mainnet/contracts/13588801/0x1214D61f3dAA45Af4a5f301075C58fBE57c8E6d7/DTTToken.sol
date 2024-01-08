// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./ERC20.sol";

contract DTTToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("DeFI Trade Token", "DTT") {
        _mint(msg.sender, initialSupply);
    }
}