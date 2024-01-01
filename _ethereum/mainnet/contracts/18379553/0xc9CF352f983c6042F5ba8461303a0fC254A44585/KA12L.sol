// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 12 Lessons
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    // 12 Lessons             //
//    // KEVIN ABOSCH (2023)    //
//                              //
//                              //
//////////////////////////////////


contract KA12L is ERC721Creator {
    constructor() ERC721Creator("12 Lessons", "KA12L") {}
}
