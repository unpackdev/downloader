
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PLUS-ONE Gallery
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    +1 /// PLUS-ONE Gallery /// +1    //
//                                      //
//                                      //
//////////////////////////////////////////


contract PLUSONE is ERC721Creator {
    constructor() ERC721Creator("PLUS-ONE Gallery", "PLUSONE") {}
}
