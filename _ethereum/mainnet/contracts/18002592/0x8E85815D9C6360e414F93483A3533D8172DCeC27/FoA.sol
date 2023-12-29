// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Flowers of Alfirin
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//                                                                         //
//    █▀▀ █░░ █▀█ █░█░█ █▀▀ █▀█ █▀   █▀█ █▀▀   ▄▀█ █░░ █▀▀ █ █▀█ █ █▄░█    //
//    █▀░ █▄▄ █▄█ ▀▄▀▄▀ ██▄ █▀▄ ▄█   █▄█ █▀░   █▀█ █▄▄ █▀░ █ █▀▄ █ █░▀█    //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract FoA is ERC721Creator {
    constructor() ERC721Creator("Flowers of Alfirin", "FoA") {}
}
