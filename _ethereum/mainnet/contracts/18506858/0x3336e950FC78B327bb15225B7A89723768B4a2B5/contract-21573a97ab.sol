// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";

contract A1SportDapp is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("A1SportDapp", "A1SD") ERC20Permit("A1SportDapp") {
        _mint(msg.sender, 10000000000 * (10 ** 18));
    }
}
