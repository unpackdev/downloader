
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: You're In A Movie
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//                         //
//      _    _   ____      //
//     | |  | | |  _ \     //
//     | |__| | | |_) |    //
//     |  __  | |  _ <     //
//     | |  | | | |_) |    //
//     |_|  |_| |____/     //
//                         //
//                         //
//                         //
//                         //
//                         //
/////////////////////////////


contract HBYINMV is ERC721Creator {
    constructor() ERC721Creator("You're In A Movie", "HBYINMV") {}
}
