// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Satoshi's Closet 2024 Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    SATOSHI'S CLOSET 2024 Editions    //
//    ASCII art is for suckas           //
//                                      //
//                                      //
//////////////////////////////////////////


contract STCL2024E is ERC1155Creator {
    constructor() ERC1155Creator("Satoshi's Closet 2024 Editions", "STCL2024E") {}
}
