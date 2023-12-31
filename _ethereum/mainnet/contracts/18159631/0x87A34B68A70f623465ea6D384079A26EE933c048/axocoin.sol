
/*
https://axocoin.org/
https://t.me/AXOCoinEntrance
https://twitter.com/AXO_Coin_

AXO Coin
Community Renewed,
Future Redefined
Step into the extraordinary realm of AXO Coin, 
a revolutionary project inspired by the remarkable regenerative abilities of the axolotl. 
Our mission is to harness the potential of healing and regeneration, 
while fostering a vibrant community united by shared values and aspirations. 
AXO Coin is more than just a cryptocurrency; it’s an embodiment of resilience and growth.
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract AXOCoin is ERC20 { 
    constructor() ERC20("AXO Coin", "AXO") { 
        _mint(msg.sender, 1_000_000_000 * 10**18);
        }
}