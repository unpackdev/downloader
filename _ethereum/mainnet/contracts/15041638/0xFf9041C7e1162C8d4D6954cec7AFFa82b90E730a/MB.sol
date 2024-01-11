
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Moon Bird
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    Shy1    //
//            //
//            //
////////////////


contract MB is ERC721Creator {
    constructor() ERC721Creator("Moon Bird", "MB") {}
}
