// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

// Contract by technopriest#0760
contract CCLToken is ERC20 {
    constructor()
    ERC20("crypto.cat.lawyer", "CCL")
    {
        // mint 1 billion coins
        _mint(msg.sender, 1 * (10 ** 9) * (10 ** uint(decimals())));
    }
}
