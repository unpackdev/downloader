
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pure Rave - “Pure Rave Plays Antonín Dvořák”
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                                                          //
//                                                          //
//        ____  __  __________     _________ __   _____     //
//       / __ \/ / / / ___/ _ \   / ___/ __ `/ | / / _ \    //
//      / /_/ / /_/ / /  /  __/  / /  / /_/ /| |/ /  __/    //
//     / .___/\__,_/_/   \___/  /_/   \__,_/ |___/\___/     //
//    /_/                                                   //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract PRNFT is ERC721Creator {
    constructor() ERC721Creator(unicode"Pure Rave - “Pure Rave Plays Antonín Dvořák”", "PRNFT") {}
}
