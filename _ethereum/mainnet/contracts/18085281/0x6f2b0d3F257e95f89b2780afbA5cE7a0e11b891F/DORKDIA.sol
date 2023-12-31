/**
🎀The World of Dork Diaries🎀
Deep within the pages of "Dork Diaries" lies a world where diary entries become gateways to the raw emotions and roller-coaster rides of teenage life. 
We plunge into the tumultuous experiences of Nikki Maxwell, a 14-year-old who faces the highs of young love and the lows of trying to fit into a new school's social hierarchy. 
From her brushes with the elite Cute, Cool & Popular clique to her enduring bonds with best friends Chloe and Zoey, Nikki's world is a vibrant tapestry of dreams, doodles, and dramas. 
The diary is a refuge, a place of solace, where every sentiment, no matter how fleeting, finds its voice. It's not just a tale; it's a testament to the resilience, passion, and spirited youthfulness that exists in every corner of the world.

💅🏻Dork Diaries💅🏻
Just as Nikki's tales appeal to a wide audience, the $DORKDIA seeks to pave the way for a new era of cryptocurrency enthusiasts who value genuine experiences and heartfelt narratives. 
Melding the world of literature with the expansive potential of blockchain, $DORKDIA is more than just a token; it's a token of appreciation for stories that move hearts.

🧏🏻‍♀️No hidden fees, no intricate tax. It’s that simple.🧏🏻‍♀️

A whopping 97% of the tokens have been allocated to the liquidity pool, with the corresponding LP tokens incinerated. 
The contract has been relinquished, ensuring a decentralized control. 
The residual 3% of the token supply is securely stored in a multi-signature wallet, reserved exclusively for future endeavors such as centralized exchange listings, establishing bridges, and bolstering liquidity pools.
Dork Diaries is crafted for the community and held in trust by its members.

💒https://dorkdiaries.vip
🏩https://t.me/DorkDiariesOfficialPortal
🧸https://twitter.com/_Dork_Diaries
**/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract DorkDiaries is ERC20 {
    constructor() ERC20("Dork Diaries", "DORKDIA") {
        _mint(msg.sender, 1_000_000_000 * 10**18);
    }
}