
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nifty B
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//     _   _ _  __ _         ____      //
//    | \ | (_)/ _| |       |  _ \     //
//    |  \| |_| |_| |_ _   _| |_) |    //
//    | . ` | |  _| __| | | |  _ <     //
//    | |\  | | | | |_| |_| | |_) |    //
//    |_| \_|_|_|  \__|\__, |____/     //
//                      __/ |          //
//                     |___/           //
//                                     //
//                                     //
/////////////////////////////////////////


contract NIFTY is ERC721Creator {
    constructor() ERC721Creator("Nifty B", "NIFTY") {}
}
