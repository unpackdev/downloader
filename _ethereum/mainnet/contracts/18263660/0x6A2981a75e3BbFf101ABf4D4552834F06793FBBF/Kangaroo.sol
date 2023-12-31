
/*
    The Kangaroo (Kangaroo)

    )\   .-''-.        
    /6 `./ _/ x\`_     .
    \/`>.-\ `  /' '-_-' 
        `` .'///  

    YOU HAVE HEARD OF A BULL OR BEAR STOCK MARKET, BUT WHAT IS A KANGAROO MARKET? A FINANCIAL ANALYST'S PERSPECTIVE

    In the world of financial analysis, we’re accustomed to categorizing markets as either “bull” or “bear,” 
    but every now and then, we encounter something different – the Kangaroo Market. It’s a term that captures 
    the peculiar nature of certain market conditions, and understanding its distinctive features is key for 
    investors and analysts alike.

    Social Media:
    - https://kangaroo.wiki
    - https://t.me/KangarooOfficialPortal
    - https://twitter.com/Kangaroo_ERC20
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract Kangaroo is ERC20 { 
    constructor() ERC20("The Kangaroo", "Kangaroo") { 
        _mint(msg.sender, 1_000_000_000 * 10**18);
    }
}