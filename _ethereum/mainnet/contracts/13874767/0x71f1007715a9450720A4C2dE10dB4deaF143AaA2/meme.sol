
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: meme0x
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    nothing to write    //
//                        //
//                        //
////////////////////////////


contract meme is ERC721Creator {
    constructor() ERC721Creator("meme0x", "meme") {}
}
