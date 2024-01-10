
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gutter Juice Vials
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    Gutter Juice Vials    //
//                          //
//                          //
//////////////////////////////


contract GJV is ERC721Creator {
    constructor() ERC721Creator("Gutter Juice Vials", "GJV") {}
}
