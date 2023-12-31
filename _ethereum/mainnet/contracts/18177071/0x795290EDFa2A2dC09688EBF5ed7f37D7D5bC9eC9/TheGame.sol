// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Game
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    The Game    //
//                //
//                //
////////////////////


contract TheGame is ERC721Creator {
    constructor() ERC721Creator("The Game", "TheGame") {}
}
