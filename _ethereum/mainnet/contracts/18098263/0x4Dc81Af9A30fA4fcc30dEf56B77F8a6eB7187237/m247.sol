// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: meme24/7
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    open 24h/7d    //
//                   //
//                   //
///////////////////////


contract m247 is ERC1155Creator {
    constructor() ERC1155Creator("meme24/7", "m247") {}
}
