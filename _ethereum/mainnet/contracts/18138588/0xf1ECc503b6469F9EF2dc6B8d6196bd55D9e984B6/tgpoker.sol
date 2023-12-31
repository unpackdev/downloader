
/*
https://tgpoker.bet/
https://t.me/TGPOKEROfficialPortal
https://twitter.com/TGPOKER_

whitepaper:
https://tgpoker.bet/wp-content/uploads/2023/09/Whitepaper.pdf

Discover TGPOKER
Your Ultimate Poker Destination
At TGPOKER, we don’t just offer poker; 
we present an entire universe of possibilities within the Telegram messaging app. 
It’s where poker enthusiasts meet, play, and connect like never before. 
Let’s dive deep into the TGPOKER experience, 
where every feature is designed to elevate your poker game and social interactions.
uilding Poker Connections with

-Online Status
Never miss a beat with TGPOKER’s online status feature. It’s your window into the poker world. 
See who’s online and which tables they’re dominating. Connect with fellow poker aficionados effortlessly.

-Invitations and Networking
TGPOKER is all about community. Add friends with a simple click, invite them to your table, or join theirs. 
It’s more than a game; it’s about building connections and enjoying poker together.

-Referrals Turned Friends
We know that referrals are valuable. That’s why TGPOKER automatically converts your referrals into friends, 
expanding your network and enhancing your overall poker experience.
*/
// 1 billion total supply

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract TGPOKER is ERC20 { 
    constructor() ERC20("TGPOKER", "TGPOKER") { 
        _mint(msg.sender, 1_000_000_000 * 10**18);
        }
}