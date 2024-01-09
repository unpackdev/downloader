
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: mouth piece
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    mouth piece    //
//                   //
//                   //
///////////////////////


contract grillz is ERC721Creator {
    constructor() ERC721Creator("mouth piece", "grillz") {}
}
