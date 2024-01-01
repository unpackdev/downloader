// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Potatoz
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                                                                                              //
//    9,999 SMALL SPECIES LEADING THE WAY TO MEMELAND.                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                              //
//    A long time ago, in a memetaverse far, far away… Memeland was a deserted land unsuitable for life. Until [redacted] years ago, early lifeforms started to appear. Memeland's first residents, it turns out, were a bunch of Potatoz. Who left the Potatoz there?                                          //
//                                                                                                                                                                                                                                                                                                              //
//    The Potatoz is a collection of 9,999 utility-enabled PFPs. Each Potatoz is your entry ticket into the great Memeland ecosystem. They make for a great side dish, but some may feel a calling to become the main course. Rumour has it they are secretly related to the Memelist, $MEME, MVP, and more!    //
//                                                                                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract pot is ERC721Creator {
    constructor() ERC721Creator("The Potatoz", "pot") {}
}
