
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Purz
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    ██████  ██    ██ ██████  ███████     //
//    ██   ██ ██    ██ ██   ██    ███      //
//    ██████  ██    ██ ██████    ███       //
//    ██      ██    ██ ██   ██  ███        //
//    ██       ██████  ██   ██ ███████     //
//                                         //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract purz is ERC721Creator {
    constructor() ERC721Creator("Purz", "purz") {}
}
