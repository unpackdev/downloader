// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DeryaGogeerArt
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    DeryaGogeerArtContract    //
//                              //
//                              //
//////////////////////////////////


contract DGA is ERC721Creator {
    constructor() ERC721Creator("DeryaGogeerArt", "DGA") {}
}
