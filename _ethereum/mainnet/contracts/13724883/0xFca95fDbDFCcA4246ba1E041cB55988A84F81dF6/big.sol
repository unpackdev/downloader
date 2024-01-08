// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Capped.sol";

contract BigPotToken is ERC20Capped {
    uint256 constant MAX_SUPPLY = 100_000_000 * 1e18;

    constructor ()
    ERC20("BigPot Token", "BIG")
    ERC20Capped(MAX_SUPPLY)
    {
        ERC20._mint(_msgSender(), MAX_SUPPLY);
    }
}