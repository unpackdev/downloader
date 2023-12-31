// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

// Dexter will change the world.
// https://dexter.cash/

// James Clerk Maxwell: Mathematics is the door and key to the sciences.
contract MyToken is ERC20 {
    constructor(string memory name, string memory symbol,uint256 initialSupply) ERC20(name, symbol) payable{
        _mint(msg.sender, initialSupply  * 10 ** uint(decimals()));
    }
}
