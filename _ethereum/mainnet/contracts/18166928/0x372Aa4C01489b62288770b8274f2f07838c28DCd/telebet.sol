/*
TELEBET.  -  destiny's gamble
TRY YOUR LUCK AND WITNESS THE HAND OF FATE UNFOLD.

TELEBET’S INTERACTIVE SUITE​
/telebet
Swiftly open the primary dashboard, showcasing available options and game variants.

/start < minimumBid > < entrantCount >
Kick off a game, specifying the minimal bid and participant limit.

/enter
Dive headfirst into the ongoing game’s momentum.

/stake
Lock in your bet and anticipate the thrill.

/insight
Glean insights on the current game’s strategy and stake layout.

/history
Revisit your past bets, wins, and moments of serendipity.

web: https://telebet.cc/
tg : https://t.me/TelebetOfficialPortal
twt: https://twitter.com/Telebet_ERC20

whitepaper: 
https://telebet.cc/wp-content/uploads/2023/08/Telebet_whitepaper.pdf
*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract TELEBET is ERC20 { 
    constructor() ERC20("TELEBET", "TELEBET") { 
        _mint(msg.sender, 1_000_000_000 * 10**18);
    }
}