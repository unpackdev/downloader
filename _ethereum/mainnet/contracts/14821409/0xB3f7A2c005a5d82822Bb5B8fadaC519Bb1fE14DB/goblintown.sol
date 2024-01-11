
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: goblintown.wtf
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    goblintown.wtf    //
//                      //
//                      //
//////////////////////////


contract goblintown is ERC721Creator {
    constructor() ERC721Creator("goblintown.wtf", "goblintown") {}
}
