
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Life We Bring
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                      //
//                                                                                                                                                                                                      //
//    "The Life We Bring" Collection by Brendan S Bigney (Nuclear Cowboy), Marine Corps Veteran, Photographer, Multi-Award-Winning Author, and Internationally Recognized Public Speaker and Leader.    //
//                                                                                                                                                                                                      //
//    nuclearcowboy.com                                                                                                                                                                                 //
//                                                                                                                                                                                                      //
//                                                                                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LIFE is ERC721Creator {
    constructor() ERC721Creator("The Life We Bring", "LIFE") {}
}
