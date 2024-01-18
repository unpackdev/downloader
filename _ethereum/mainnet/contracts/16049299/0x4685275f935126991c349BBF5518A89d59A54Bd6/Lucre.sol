// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC20.sol";
import "./ERC20Burnable.sol";


// Basic ERC20 burnable coin for CPC by @vj
contract Lucre is ERC20, ERC20Burnable {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}