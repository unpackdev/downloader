// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Permit.sol";

contract KKK is ERC20, ERC20Permit {
    constructor() ERC20("KKK", "KKK") ERC20Permit("KKK") {
        _mint(msg.sender, 100000000000 * 10 ** decimals());
    }
}
