
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PB Test
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    Juru Labs    //
//                 //
//                 //
/////////////////////


contract PBT is ERC721Creator {
    constructor() ERC721Creator("PB Test", "PBT") {}
}
