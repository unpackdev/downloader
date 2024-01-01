
/*
In Acid Frog's world, reality bends. Flesh circulates under ethereal veils, while silent power hums. 
Ponder life's riddles - is your fridge orbiting the unknown? 
Witness the constricting sky and savor the taste of metallic twilight. With $AROG, circulate endlessly.

TAX 0%
LP LOCKED

W: https://acidfrog.co/
T: https://t.me/AcidFrogPortal
X: https://twitter.com/Acid_Frog_
*/



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract AROG is ERC20 { 
    constructor() ERC20("Acid Frog", "AROG") { 
        _mint(msg.sender, 1_000_000_000 * 10**18);
    }
}