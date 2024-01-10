
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nihan's unique arts
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    Nihan's unique artworks    //
//                               //
//                               //
///////////////////////////////////


contract NIHAN is ERC721Creator {
    constructor() ERC721Creator("Nihan's unique arts", "NIHAN") {}
}
