
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: I Put A Hex On You
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//                         //
//                         //
//             ____  __    //
//      /\  /\/__\ \/ /    //
//     / /_/ /_\  \  /     //
//    / __  //__  /  \     //
//    \/ /_/\__/ /_/\_\    //
//                         //
//                         //
/////////////////////////////


contract hexu is ERC721Creator {
    constructor() ERC721Creator("I Put A Hex On You", "hexu") {}
}
