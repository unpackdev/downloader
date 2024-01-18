
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Amana Live2D Studio Movie
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    live2d video    //
//                    //
//                    //
////////////////////////


contract AL2M is ERC721Creator {
    constructor() ERC721Creator("Amana Live2D Studio Movie", "AL2M") {}
}
