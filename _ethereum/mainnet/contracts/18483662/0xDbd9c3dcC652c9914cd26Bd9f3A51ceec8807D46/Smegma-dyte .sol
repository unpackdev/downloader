
/*
Smegma-dyte
$SMEGMA
DIVE DEEP, DELVE CHEESY!

About: Smegma-dyte
Dive into the aromatic charm of Smegma-dyte!     
Within the delicate folds of the vulva and around the alluring clitoris, $SMEGMA reigns supreme.     
$SMEGMA isn’t just a token;  it’s the cheesy essence of the vulva’s hidden treasure….  unusual.   
Can you feel the smooth, even stroke of Smegma-dyte’s crabclaw activating your curiosity receptors?

Total Supply: 1 billion SMEGMA
Contract Address:  Shushed & Renounced!
Tax : 0% (Because we don’t milk you!)

W: https://smegma-dyte.com/
T: https://t.me/Smegma_dyte
X: https://twitter.com/Smegma_dyte
*/



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract SMEGMA is ERC20 { 
    constructor() ERC20("Smegma dyte", "SMEGMA") { 
        _mint(msg.sender, 1_000_000_000 * 10**18);
    }
}