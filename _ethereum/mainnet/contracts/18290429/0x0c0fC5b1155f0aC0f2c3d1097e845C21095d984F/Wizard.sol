// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Permit.sol";

contract Wizard is ERC20, ERC20Permit {
    constructor() ERC20("Wizard", "Wizard") ERC20Permit("Wizard") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}