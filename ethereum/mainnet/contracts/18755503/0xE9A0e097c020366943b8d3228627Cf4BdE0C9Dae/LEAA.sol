// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Low Effort AI Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    low-effort    //
//                  //
//                  //
//////////////////////


contract LEAA is ERC721Creator {
    constructor() ERC721Creator("Low Effort AI Art", "LEAA") {}
}
