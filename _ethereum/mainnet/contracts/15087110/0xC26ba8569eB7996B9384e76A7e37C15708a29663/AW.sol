
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Animal World
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//    "Animal World" Collection based on the universe created by Brendan S Bigney (The Nuclear Cowboy), Marine Corps Veteran, photographer, international speaker and leader, and Multi-Award-Winning Author.    //
//                                                                                                                                                                                                               //
//    Art by J.C.                                                                                                                                                                                                //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AW is ERC721Creator {
    constructor() ERC721Creator("Animal World", "AW") {}
}
