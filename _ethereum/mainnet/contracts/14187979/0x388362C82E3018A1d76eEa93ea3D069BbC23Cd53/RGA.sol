
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Reynolds Gonzales Artwork
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    reynolds gonzales artwork    //
//                                 //
//                                 //
/////////////////////////////////////


contract RGA is ERC721Creator {
    constructor() ERC721Creator("Reynolds Gonzales Artwork", "RGA") {}
}
