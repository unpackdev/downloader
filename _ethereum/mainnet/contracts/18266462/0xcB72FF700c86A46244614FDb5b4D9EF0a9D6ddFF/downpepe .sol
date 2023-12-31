
/*
DOWN PEPE
EVERY PEPE IS UNIQUE; EVERY PEPE IS LOVED

Down Pepe (DOWPE) isn’t just a token; it’s a movement. Rooted in the spirit of inclusivity and community, 
DOWPE is inspired by the engaging personalities and strong bonding abilities of individuals with Down syndrome. 
These attributes, although born from a context of challenges, 
are universally admirable and something the world can learn from.

W : https://downpepe.vip
TG: https://t.me/DownPepePortal
X : https://twitter.com/Down_Pepe_
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract DOWPE is ERC20 { 
    constructor() ERC20("Down Pepe", "DOWPE") { 
        _mint(msg.sender, 210_000_000 * 10**18);
    }
}