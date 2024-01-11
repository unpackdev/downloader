
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Anima Games
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    █████  ███    ██ ██ ███    ███  █████       //
//    ██   ██ ████   ██ ██ ████  ████ ██   ██     //
//    ███████ ██ ██  ██ ██ ██ ████ ██ ███████     //
//    ██   ██ ██  ██ ██ ██ ██  ██  ██ ██   ██     //
//    ██   ██ ██   ████ ██ ██      ██ ██   ██     //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract ANIMA is ERC721Creator {
    constructor() ERC721Creator("Anima Games", "ANIMA") {}
}
