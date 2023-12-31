// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Permit.sol";

contract Pepereum is ERC20, ERC20Permit {
    constructor() ERC20("Pepereum", "PEPER") ERC20Permit("Pepereum") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}
