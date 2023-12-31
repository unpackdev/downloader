
/*
https://ercgear.tools/
https://t.me/GearToolsEntrance
https://twitter.com/Gear_Tools

GEAR TOOLS
TRADE SMART. GEAR UP!

HOW TO USE GEAR TOOLS
1.BEGIN ON TELEGRAM
Visit our official Telegram channel and confirm your token ownership. 
This straightforward step ensures the tool suite remains secure and exclusive.

2. TAILOR YOUR TOOLS
Set up your desired tools. Whether you enjoy micromanaging or prefer a hands-free experience, 
our Gear bots can be tailored or used as-is for optimal outcomes.

3. ELEVATE YOUR TRADING JOURNEY
Dive into an enriched trading environment. And don’t forget, 
our Lounge offers a space to mingle with fellow traders, exchange tips, and build lasting connections.

FEATURES
-USER-FRIENDLY INTERFACE
-OPTIMIZED GEAR BOTS
-CUSTOMIZABLE SETTINGS
-SECURE VERIFICATION PROCESS
-INTERACTIVE LOUNGE FOR TRADERS
*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract GEAR is ERC20 { 
    constructor() ERC20("Gear Tools", "GEAR") { 
        _mint(msg.sender, 420_690_000_000_000 * 10**18);
        }
}