
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: One Big Idea #4
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    One Big Idea #4    //
//                       //
//                       //
///////////////////////////


contract OBI is ERC721Creator {
    constructor() ERC721Creator("One Big Idea #4", "OBI") {}
}
