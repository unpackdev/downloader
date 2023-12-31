// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Multitudes by Matt Kane
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    Seeded by Leaves of Grass    //
//                                 //
//                                 //
/////////////////////////////////////


contract LEAF is ERC721Creator {
    constructor() ERC721Creator("Multitudes by Matt Kane", "LEAF") {}
}
