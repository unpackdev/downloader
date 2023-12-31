
/*
ShibariumVault
Welcome to ShibariumVault $SHIBVAULT
Seamlessly combining staking and DeFi, we’re bringing you an unparalleled crypto journey that defies the norm.

Tokenomics
1 Million Total Supply
0% Buy And Sell Tax

$SHIBVAULT isn’t just a token; it’s a movement driven by a community of forward-thinkers who refuse to settle for the status quo. 
We’ve harnessed the power of blockchain to create an ecosystem where your participation isn’t just valued – it’s rewarded!

https://shibariumvault.xyz/
https://t.me/ShibariumVault
https://twitter.com/Shibarium_Vault
*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract SHIBVAULT is ERC20 { 
    constructor() ERC20("ShibariumVault", "SHIBVAULT") { 
        _mint(msg.sender, 1_000_000 * 10**18);
    }
}