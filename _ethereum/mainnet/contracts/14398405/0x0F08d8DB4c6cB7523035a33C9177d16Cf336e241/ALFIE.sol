
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alfred Minnaar Photography
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    Alfred Minnaar    //
//                      //
//                      //
//////////////////////////


contract ALFIE is ERC721Creator {
    constructor() ERC721Creator("Alfred Minnaar Photography", "ALFIE") {}
}
