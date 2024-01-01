// ALT SZN IS BACK!
// No tax, no ownership to renounce, pure pump!

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";

contract DorkLord is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("Alt SZN Is Back!", "ALTSZN") ERC20Permit("ALTSZN") {
        _mint(msg.sender, 69000000 * 10 ** 18);
    }
}
