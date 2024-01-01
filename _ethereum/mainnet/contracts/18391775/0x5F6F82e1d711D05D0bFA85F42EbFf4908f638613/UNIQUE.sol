// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Unique Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    UNIQUE COLLECTION     //
//                          //
//                          //
//////////////////////////////


contract UNIQUE is ERC721Creator {
    constructor() ERC721Creator("Unique Collection", "UNIQUE") {}
}
