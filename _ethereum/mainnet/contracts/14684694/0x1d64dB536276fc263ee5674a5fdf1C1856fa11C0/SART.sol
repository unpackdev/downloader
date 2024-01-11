
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Special art of the whole world
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    0xArt0nChain    //
//                    //
//                    //
////////////////////////


contract SART is ERC721Creator {
    constructor() ERC721Creator("Special art of the whole world", "SART") {}
}
