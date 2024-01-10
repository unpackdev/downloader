
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rohan's Madolci - Voice Comics
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//      Animated Manga                       //
//    : Madolci Recipes - Daily Episodes.    //
//                                           //
//                                           //
///////////////////////////////////////////////


contract Madolce is ERC721Creator {
    constructor() ERC721Creator("Rohan's Madolci - Voice Comics", "Madolce") {}
}
