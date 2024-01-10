
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alfie Motion 1/1s
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    alfiemotion    //
//                   //
//                   //
///////////////////////


contract AM is ERC721Creator {
    constructor() ERC721Creator("Alfie Motion 1/1s", "AM") {}
}
