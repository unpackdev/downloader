// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Permit.sol";

contract PEPEREUM is ERC20, ERC20Permit {
    constructor() ERC20("PEPEREUM", "PEPEREUM") ERC20Permit("PEPEREUM") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}
