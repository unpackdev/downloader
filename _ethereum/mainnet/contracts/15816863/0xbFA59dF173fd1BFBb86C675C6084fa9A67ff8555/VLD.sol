
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: veiled
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    artembel    //
//                //
//                //
////////////////////


contract VLD is ERC721Creator {
    constructor() ERC721Creator("veiled", "VLD") {}
}
