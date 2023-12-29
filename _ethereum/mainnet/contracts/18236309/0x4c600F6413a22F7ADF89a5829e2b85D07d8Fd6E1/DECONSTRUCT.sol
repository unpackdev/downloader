// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DECONSTRUCTED
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    GRID GAMES    //
//                  //
//                  //
//////////////////////


contract DECONSTRUCT is ERC721Creator {
    constructor() ERC721Creator("DECONSTRUCTED", "DECONSTRUCT") {}
}
