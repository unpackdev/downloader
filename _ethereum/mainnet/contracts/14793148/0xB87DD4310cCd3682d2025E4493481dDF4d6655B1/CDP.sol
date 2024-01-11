
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Carlos' Avatars
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    |--------------    //
//    |                  //
//    |                  //
//    |                  //
//    |                  //
//    |                  //
//    |                  //
//    |                  //
//    |                  //
//    |                  //
//    |                  //
//    |--------------    //
//                       //
//                       //
///////////////////////////


contract CDP is ERC721Creator {
    constructor() ERC721Creator("Carlos' Avatars", "CDP") {}
}
