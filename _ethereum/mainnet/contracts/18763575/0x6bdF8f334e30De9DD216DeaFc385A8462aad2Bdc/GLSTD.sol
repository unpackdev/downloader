// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GlassToad
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    GlassToad by Nat    //
//                        //
//                        //
////////////////////////////


contract GLSTD is ERC721Creator {
    constructor() ERC721Creator("GlassToad", "GLSTD") {}
}
