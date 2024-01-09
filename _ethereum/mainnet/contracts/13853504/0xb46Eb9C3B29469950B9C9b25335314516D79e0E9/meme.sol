
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: meme
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    meme    //
//            //
//            //
////////////////


contract meme is ERC721Creator {
    constructor() ERC721Creator("meme", "meme") {}
}
