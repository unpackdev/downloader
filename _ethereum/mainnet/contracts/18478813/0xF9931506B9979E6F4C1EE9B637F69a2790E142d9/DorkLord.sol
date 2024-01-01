// Welcome to the DORK side
// Up your ranking among all DORK LORDS out there. The army is waiting for you! 
// https://dorkled.com/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";

contract DorkLord is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("Dork Lord", "DORKL") ERC20Permit("DORKL") {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }
}
