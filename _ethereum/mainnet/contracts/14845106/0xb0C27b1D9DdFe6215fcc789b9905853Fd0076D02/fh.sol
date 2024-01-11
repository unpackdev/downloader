
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: fishing holes
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                               _                 //
//          -                   | |                //
//      __,     ,_    __,    _  | |     _   _      //
//     /  | |  /  |  /  |  |/ \_|/ \   |/  |/      //
//    \_/|/|_/   |_/\_/|_/|__/ |   |_/|__/|__/     //
//       /|               /|                       //
//       \|               \|                       //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract fh is ERC721Creator {
    constructor() ERC721Creator("fishing holes", "fh") {}
}
