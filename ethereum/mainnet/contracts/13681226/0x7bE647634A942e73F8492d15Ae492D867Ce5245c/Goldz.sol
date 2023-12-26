// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./draft-ERC20Permit.sol";

contract FeudalzGoldz is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("Feudalz Goldz", "GOLDZ") ERC20Permit("Feudalz Goldz") {
        _mint(msg.sender, 5_000_000 * 10 ** decimals());
    }
}