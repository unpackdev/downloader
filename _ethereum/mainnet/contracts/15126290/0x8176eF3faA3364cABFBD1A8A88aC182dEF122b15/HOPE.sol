
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hope (Nuclear Cowboy)
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                       //
//                                                                                                                                       //
//    "Hope" Collection by Brendan S Bigney (The Nuclear Cowboy), Marine Corps Veteran, photographer, and Multi-Award-Winning Author.    //
//                                                                                                                                       //
//    nuclearcowboy.com                                                                                                                  //
//                                                                                                                                       //
//                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HOPE is ERC721Creator {
    constructor() ERC721Creator("Hope (Nuclear Cowboy)", "HOPE") {}
}
