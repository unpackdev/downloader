// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";

contract GriftCoin is ERC20 {
    constructor(uint256 initialSupply) ERC20("GriftCoin", "GRIFT") {
        _mint(msg.sender, initialSupply);
    }
}
