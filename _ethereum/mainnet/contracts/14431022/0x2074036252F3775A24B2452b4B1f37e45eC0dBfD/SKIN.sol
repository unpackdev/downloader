
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: I Like Your Skin
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    Clearing__Contract    //
//                          //
//                          //
//////////////////////////////


contract SKIN is ERC721Creator {
    constructor() ERC721Creator("I Like Your Skin", "SKIN") {}
}
