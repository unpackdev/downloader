
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Doge in the metaverse
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    art collection    //
//                      //
//                      //
//////////////////////////


contract DTM is ERC721Creator {
    constructor() ERC721Creator("Doge in the metaverse", "DTM") {}
}
