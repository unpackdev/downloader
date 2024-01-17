
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FUZZGAFF
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    FUZZGAFF    //
//                //
//                //
////////////////////


contract FUZZ is ERC721Creator {
    constructor() ERC721Creator("FUZZGAFF", "FUZZ") {}
}
