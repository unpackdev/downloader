
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Faceless Portraits
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//     _   _____  __     _ _  __   _  __  __  _____     //
//    /_)_(_)/ (_/ (_(_/_(/__/ (__(/_/ (_/ (_(_)/ (_    //
//                  .-/                                 //
//                 (_/                                  //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract FACELESS is ERC721Creator {
    constructor() ERC721Creator("Faceless Portraits", "FACELESS") {}
}
