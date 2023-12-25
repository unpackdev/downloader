// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./draft-ERC20Permit.sol";

contract LBP is ERC20, ERC20Permit {
    constructor() ERC20("Launch Block", "LBP") ERC20Permit("Launch Block") {
        _mint(msg.sender, 10000000000e18);
    }
}
