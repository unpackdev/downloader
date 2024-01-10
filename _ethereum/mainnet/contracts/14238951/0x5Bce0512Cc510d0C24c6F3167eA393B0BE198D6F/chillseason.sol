
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: a picture by Jon Alexander
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    a picture by Jon Alexander    //
//                                  //
//                                  //
//////////////////////////////////////


contract chillseason is ERC721Creator {
    constructor() ERC721Creator("a picture by Jon Alexander", "chillseason") {}
}
