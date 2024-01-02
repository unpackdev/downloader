// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Earth
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    ███████  █████  ██████  ████████ ██   ██     //
//    ██      ██   ██ ██   ██    ██    ██   ██     //
//    █████   ███████ ██████     ██    ███████     //
//    ██      ██   ██ ██   ██    ██    ██   ██     //
//    ███████ ██   ██ ██   ██    ██    ██   ██     //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract Earth is ERC721Creator {
    constructor() ERC721Creator("Earth", "Earth") {}
}
