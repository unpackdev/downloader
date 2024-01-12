
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Smirk
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                              //
//    ███████ ███    ███ ██ ██████  ██   ██     //
//    ██      ████  ████ ██ ██   ██ ██  ██      //
//    ███████ ██ ████ ██ ██ ██████  █████       //
//         ██ ██  ██  ██ ██ ██   ██ ██  ██      //
//    ███████ ██      ██ ██ ██   ██ ██   ██     //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract SMIRK is ERC721Creator {
    constructor() ERC721Creator("Smirk", "SMIRK") {}
}
