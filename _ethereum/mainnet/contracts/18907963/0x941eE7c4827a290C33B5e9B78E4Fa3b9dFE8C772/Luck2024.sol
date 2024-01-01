// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";

contract Luck2024 is ERC20 {
    constructor(uint256 initialSupply) ERC20("FORTUNA2024", "FORTUNA2024") {
        _mint(msg.sender, initialSupply);
    }
}
