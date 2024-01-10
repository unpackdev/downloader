
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sleepy Artworks
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Sleepy Artworks    //
//                       //
//                       //
///////////////////////////


contract SLPA is ERC721Creator {
    constructor() ERC721Creator("Sleepy Artworks", "SLPA") {}
}
