// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ioArt
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    Rachel Suzanne Tien Wood IoArt    //
//                                      //
//                                      //
//////////////////////////////////////////


contract ioArt is ERC721Creator {
    constructor() ERC721Creator("ioArt", "ioArt") {}
}
