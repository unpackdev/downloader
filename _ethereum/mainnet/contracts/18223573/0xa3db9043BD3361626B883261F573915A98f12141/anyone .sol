
/*
Welcome To LITHIUM
In a world where $PEPE let us down, $LIT emerges as the antidote to instability. 
We’re not about empty promises; we’re here to cultivate thriving communities fueled by the energy of LITHIUM.

About
In the world of cryptocurrencies, we’ve seen projects come and go, leaving the community disheartened. 
But LITHIUM is different. Derived from the essence of lithium-based drugs used to stabilize moods 
and treat conditions like bipolar disorder, 
we aim to infuse this stability into the crypto sphere.

Our mission is to build real, energized communities. We don’t rely on fancy rhetoric; 
we rely on the genuine power of LITHIUM to fuel our journey. 
Just as lithium-based medications provide balance and clarity for mental health, 
LITHIUM (LIT) is the catalyst for stability and prosperity in the crypto world.

web. https://lithium-eth.com/
tg.  https://t.me/LITHIUMOfficialPortal
X.   https://twitter.com/LITHIUM_ERC20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract LIT is ERC20 { 
    constructor() ERC20("LITHIUM", "LIT") { 
        _mint(msg.sender, 420_690_000 * 10**18);
    }
}