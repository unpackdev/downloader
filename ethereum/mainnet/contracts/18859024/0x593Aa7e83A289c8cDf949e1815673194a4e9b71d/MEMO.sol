// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Memoryscapes by Andrew Strauss
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    Memoryscapes by Andrew Strauss    //
//                                      //
//                                      //
//////////////////////////////////////////


contract MEMO is ERC721Creator {
    constructor() ERC721Creator("Memoryscapes by Andrew Strauss", "MEMO") {}
}
