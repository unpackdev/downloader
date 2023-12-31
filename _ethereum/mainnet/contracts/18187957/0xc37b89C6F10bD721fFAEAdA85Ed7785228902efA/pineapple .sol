
// PINEAPPLE
// THAT’S PINEAPPLE - JUICY PROFITS, NO AWKWARDNESS
// WEB: https://pineapplecoin.co
// X:   https://twitter.com/Pineapple_ERC20
// TG:  https://t.me/PineappleOfficialPortal

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract PINEAPPLE is ERC20 { 
    constructor() ERC20("Pineapple", "PINEAPPLE") { 
        _mint(msg.sender, 420_690_000_000 * 10**18);
    }
}