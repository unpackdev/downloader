/*
YUJIRO - 地球上で最強のトークン
Channeling the might of Yuujirou Hanma, the "Ogre" of Baki's universe, 
the YUJIRO Token represents more than just another cryptocurrency. 
It symbolizes strength, perseverance, and unmatched dominance. 
Just as Yuujirou stands tall amidst the fiercest of fighters, $YUJIRO will become the Strongest Token on Earth.

NO TAX, NO TEAM TOKEN, NO BULLSHIT!
LOCK and RENOUNCE, 100% SAFE.
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract YUJIRO is ERC20 { 
    constructor() ERC20("Yujiro", "YUJIRO") { 
        _mint(msg.sender, 420_000_000 * 10**18);
    }
}