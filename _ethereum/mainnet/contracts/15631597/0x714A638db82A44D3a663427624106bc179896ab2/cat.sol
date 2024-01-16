
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Porcelain cat Club
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    Porcelain cat Club    //
//                          //
//                          //
//////////////////////////////


contract cat is ERC721Creator {
    constructor() ERC721Creator("Porcelain cat Club", "cat") {}
}
