// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";

contract BEEF is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("BEEF", "BEEF") ERC20Permit("BEEF") {
        _mint(msg.sender, 100000000000 * 10 ** decimals());
    }
}
