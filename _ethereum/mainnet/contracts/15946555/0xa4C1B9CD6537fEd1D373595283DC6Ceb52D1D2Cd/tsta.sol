
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: test
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    test    //
//            //
//            //
////////////////


contract tsta is ERC721Creator {
    constructor() ERC721Creator("test", "tsta") {}
}
