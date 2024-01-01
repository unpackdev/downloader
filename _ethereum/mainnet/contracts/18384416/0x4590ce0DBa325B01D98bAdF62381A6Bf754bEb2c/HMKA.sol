// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HACKER MAG by Kevin Abosch
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    // HACKER MAG      //
//    // KEVIN ABOSCH    //
//    // 2023            //
//                       //
//                       //
///////////////////////////


contract HMKA is ERC721Creator {
    constructor() ERC721Creator("HACKER MAG by Kevin Abosch", "HMKA") {}
}
