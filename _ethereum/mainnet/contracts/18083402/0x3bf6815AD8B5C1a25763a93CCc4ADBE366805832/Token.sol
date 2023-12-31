// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./draft-ERC20Permit.sol";

contract Token is ERC20, ERC20Permit {
    uint256 constant TOTAL_SUPPLY = 100_000_000_000 * 10 ** 18;
    
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) ERC20Permit(name_) {
        _mint(msg.sender, TOTAL_SUPPLY);
    }
}