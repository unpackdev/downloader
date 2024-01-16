
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: j.0x00n
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    » j.0x00n's NFT contract «    //
//                                  //
//                                  //
//////////////////////////////////////


contract JUNE is ERC721Creator {
    constructor() ERC721Creator("j.0x00n", "JUNE") {}
}
