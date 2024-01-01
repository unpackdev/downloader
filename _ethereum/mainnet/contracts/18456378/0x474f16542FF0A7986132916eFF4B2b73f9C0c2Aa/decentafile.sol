// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Permit.sol";

contract DecentraFile is ERC20, ERC20Permit {
    constructor() ERC20("DecentraFile", "DFM") ERC20Permit("DecentraFile") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}