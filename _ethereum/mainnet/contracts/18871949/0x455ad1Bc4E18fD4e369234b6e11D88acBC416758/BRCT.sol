// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";

contract BRCT is ERC20, ERC20Burnable, ERC20Permit {
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 ether;

    constructor() ERC20("BRCT", "BRCT") ERC20Permit("BRCT") {
        _mint(0xCFcE4EeC2909fEd5b717d66ab3C457AAae23bD4f, TOTAL_SUPPLY);
    }
}
