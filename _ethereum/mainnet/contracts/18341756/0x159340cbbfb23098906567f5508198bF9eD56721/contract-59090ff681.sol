// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Permit.sol";

contract FreePalestine is ERC20, ERC20Permit {
    constructor()
        ERC20("Free Palestine", "FreePAL")
        ERC20Permit("Free Palestine")
    {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }
}
