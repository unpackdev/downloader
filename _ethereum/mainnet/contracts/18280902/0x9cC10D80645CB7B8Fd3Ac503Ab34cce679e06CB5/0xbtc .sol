/*
0xBTC 
$0xBITCOIN

About 0xBTC
A TRANSFORMATIVE SHIFT
Are you in search of a digital currency that not only outpaces traditional banking systems in terms of speed and cost 
efficiency but also delivers unprecedented levels of privacy and security? Look no further than 0xBTC,
the freshest entrant in the cryptocurrency realm, poised to supplant fiat currencies and 
instigate a transformative shift in the way financial transactions unfold.

MECHANISM
Constructed on the foundation of the Ethereum blockchain, 
0xBTC harnesses the prowess of Zero Knowledge technology, 
a cutting-edge security framework within the Ethereum protocol. 
This revolutionary feature enables transactions to occur in a confidential and secure manner, 
shielding sensitive information from exposure and ushering in an era of discreet and safeguarded digital currency interactions.

whitepaper: 
https://0xbtc.pro/wp-content/uploads/2023/09/whitepaper.pdf

https://0xbtc.pro/
https://t.me/ZEROxBTCPortal
https://twitter.com/0xBTC_Token
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract OxBTC is ERC20 {
    constructor() ERC20("0xBTC","0xBITCOIN") { 
        _mint(msg.sender, 21_000_000 * 10**18);
    }
}