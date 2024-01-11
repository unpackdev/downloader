
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Oddstronauts Honoraries
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    Thats odd    //
//                 //
//                 //
/////////////////////


contract ODDH is ERC721Creator {
    constructor() ERC721Creator("Oddstronauts Honoraries", "ODDH") {}
}
