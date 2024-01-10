
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gutter Clones
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Gutter Clones    //
//                     //
//                     //
/////////////////////////


contract GC is ERC721Creator {
    constructor() ERC721Creator("Gutter Clones", "GC") {}
}
