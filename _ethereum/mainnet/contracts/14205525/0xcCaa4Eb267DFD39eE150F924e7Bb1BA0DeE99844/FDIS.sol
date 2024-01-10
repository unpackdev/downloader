
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Face Down in Shit
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    Clearing__Contract    //
//                          //
//                          //
//////////////////////////////


contract FDIS is ERC721Creator {
    constructor() ERC721Creator("Face Down in Shit", "FDIS") {}
}
