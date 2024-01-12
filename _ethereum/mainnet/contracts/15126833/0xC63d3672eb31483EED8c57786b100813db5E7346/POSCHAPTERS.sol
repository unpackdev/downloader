
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chapters by Proof of Story
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    Impssbl x Proof of Story    //
//                                //
//                                //
////////////////////////////////////


contract POSCHAPTERS is ERC721Creator {
    constructor() ERC721Creator("Chapters by Proof of Story", "POSCHAPTERS") {}
}
