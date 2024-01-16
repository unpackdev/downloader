
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Official Collection Tamadoge
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Tamadoge official    //
//                         //
//                         //
/////////////////////////////


contract TD is ERC721Creator {
    constructor() ERC721Creator("Official Collection Tamadoge", "TD") {}
}
