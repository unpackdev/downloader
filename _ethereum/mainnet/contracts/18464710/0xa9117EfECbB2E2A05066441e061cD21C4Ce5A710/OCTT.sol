// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OctoberTextures
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    ---///---    //
//                 //
//                 //
/////////////////////


contract OCTT is ERC721Creator {
    constructor() ERC721Creator("OctoberTextures", "OCTT") {}
}
