// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: L'alfabeto della lettera
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    Alfabeto primo    //
//                      //
//                      //
//////////////////////////


contract ALF is ERC721Creator {
    constructor() ERC721Creator("L'alfabeto della lettera", "ALF") {}
}
