// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: the facktory
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    welcome to the new era     //
//                               //
//                               //
///////////////////////////////////


contract facktory is ERC721Creator {
    constructor() ERC721Creator("the facktory", "facktory") {}
}
