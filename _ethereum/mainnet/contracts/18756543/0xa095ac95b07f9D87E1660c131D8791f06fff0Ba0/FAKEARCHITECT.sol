// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fake Architect.
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//      ___     _           _          _    _ _          _         //
//     | __|_ _| |_____    /_\  _ _ __| |_ (_) |_ ___ __| |_       //
//     | _/ _` | / / -_)  / _ \| '_/ _| ' \| |  _/ -_) _|  _|_     //
//     |_|\__,_|_\_\___| /_/ \_\_| \__|_||_|_|\__\___\__|\__(_)    //
//                                                                 //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract FAKEARCHITECT is ERC721Creator {
    constructor() ERC721Creator("Fake Architect.", "FAKEARCHITECT") {}
}
