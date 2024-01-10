
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PeterArt18 Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    PeterArt18    //
//                  //
//                  //
//////////////////////


contract PA18 is ERC721Creator {
    constructor() ERC721Creator("PeterArt18 Collection", "PA18") {}
}
