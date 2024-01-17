
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rockaway'sTrash
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//     _                 _         //
//    | |               | |        //
//    | |_ _ __ __ _ ___| |__      //
//    | __| '__/ _` / __| |_ \     //
//    | |_| | | (_| \__ \ | | |    //
//     \__|_|  \__,_|___/_| |_|    //
//                                 //
//                                 //
/////////////////////////////////////


contract TRASH is ERC721Creator {
    constructor() ERC721Creator("Rockaway'sTrash", "TRASH") {}
}
