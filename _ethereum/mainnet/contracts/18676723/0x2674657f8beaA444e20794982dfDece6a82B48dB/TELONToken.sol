// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./ERC20.sol";
import "./ERC20Permit.sol";

contract TELONToken is ERC20, ERC20Permit {
    constructor() ERC20("Troll Elon Token", "T-ELON") ERC20Permit("Troll Elon Token") {
        _mint(msg.sender, 45_000_000 * 10 ** decimals());
    }
}
