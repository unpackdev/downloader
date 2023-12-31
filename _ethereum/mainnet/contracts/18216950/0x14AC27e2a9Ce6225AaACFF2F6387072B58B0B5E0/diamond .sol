
/*
DIAMOND
Unveiling the DIAMOND!
Total Supply: 1,000,000,000

// About
Shine Bright, Hold Tight!
In the ethereal dominion of DIAMOND, hodlers aren't just average beings; 
they're cosmic legends who dance on the edges of black holes and surf on gamma-ray bursts! 
DIAMOND emerges not just only a token, but as an emblem of relentless resilience and brilliance. 

// Tokenomics
- Stealth Launch: 
Bamboozled the universe! Zero hype, ALL mystery!

- Max Wallet Size Limited: 
No space whales allowed here!

- 0% Tax: 
We'd rather fight space pirates! Absolute Stonk-Immunity: We mock gravity! Only flying upwards!

Galaxy's Own Meme: Birthed by stars, cradled by memes.

// Roadmap
Phase 1: Stellar Dawn
-Ignition! Meme rockets fueled
-Form cosmic alliances with meme overlords
-Stellar staking systems
-Astro-merch launch: Hoodies from the Heavens!

Phase 2: Galactic Glory
-Imprint DIAMOND constellations in the crypto sky
-Intergalactic contests: Spacey rewards!
-Create our DIAMOND space station
-Cosmic AMAs: Chat with the stars!

Phase 3: Universal Domination
-Colonize top-tier exchanges
-Galactic giveaways and meteoric rewards
-Establish the DIAMOND Space Academy: Educate and dominate!
-Pioneering space missions with community astronauts

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract DIAMOND is ERC20 { 
    constructor() ERC20("Diamond", "DIAMOND") { 
        _mint(msg.sender, 1_000_000_000 * 10**18);
    }
}