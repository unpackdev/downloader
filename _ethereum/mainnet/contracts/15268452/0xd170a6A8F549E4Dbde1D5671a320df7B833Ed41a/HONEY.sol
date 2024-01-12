
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Honey Wings
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                              //
//                                                                                                                                              //
//    "Honey Wings" Collection by Brendan S Bigney (The Nuclear Cowboy), Marine Corps Veteran, photographer, and Multi-Award-Winning Author.    //
//                                                                                                                                              //
//    nuclearcowboy.com                                                                                                                         //
//                                                                                                                                              //
//                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HONEY is ERC721Creator {
    constructor() ERC721Creator("Honey Wings", "HONEY") {}
}
