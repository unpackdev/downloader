// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Grimblevine Wrywhisper
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                            //
//                                                                                                                                            //
//    In a quiet corner of the room resides a mandrake named Grimblevine Wrywhisper.                                                          //
//                                                                                                                                            //
//    He slumbers deeply under a potent enchantment and grumbles fiercely if awakened. Having seen much, he cherishes his tranquil repose.    //
//                                                                                                                                            //
//    Never disturb the sleeping mandrake!                                                                                                    //
//    #c4d #octane #c4dart #otoy #3dartist #mandrake                                                                                          //
//                                                                                                                                            //
//                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ETH is ERC721Creator {
    constructor() ERC721Creator("Grimblevine Wrywhisper", "ETH") {}
}
