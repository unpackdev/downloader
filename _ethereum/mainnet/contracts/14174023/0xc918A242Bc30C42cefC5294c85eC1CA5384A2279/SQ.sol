
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Squiggles
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    Squiggles    //
//                 //
//                 //
/////////////////////


contract SQ is ERC721Creator {
    constructor() ERC721Creator("Squiggles", "SQ") {}
}
