
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Royal Highness Loyalty Coin
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    Royal Highness Loyalty Coin is your way       //
//    To get high in the Metaverse. If you want     //
//    Your NFTs to get the Royal Treatment then     //
//    Join The Family & Smoke The Finest with       //
//    Royal Highness                                //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract RHLC is ERC721Creator {
    constructor() ERC721Creator("Royal Highness Loyalty Coin", "RHLC") {}
}
