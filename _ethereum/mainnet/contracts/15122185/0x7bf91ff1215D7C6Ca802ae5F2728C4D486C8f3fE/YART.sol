
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Yuya’s Artworks
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Yuya's Artworks    //
//                       //
//                       //
///////////////////////////


contract YART is ERC721Creator {
    constructor() ERC721Creator(unicode"Yuya’s Artworks", "YART") {}
}
