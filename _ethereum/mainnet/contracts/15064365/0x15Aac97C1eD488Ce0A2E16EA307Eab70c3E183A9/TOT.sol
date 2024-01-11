
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Toterr///Punks
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    Clearing__Contract    //
//                          //
//                          //
//////////////////////////////


contract TOT is ERC721Creator {
    constructor() ERC721Creator("Toterr///Punks", "TOT") {}
}
