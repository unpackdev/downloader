
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Treasure Island
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//      _   _   _   _   _   _   _   _      //
//     / \ / \ / \ / \ / \ / \ / \ / \     //
//    ( f | e | d | e | s | t | o | l )    //
//     \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/     //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract Fed is ERC721Creator {
    constructor() ERC721Creator("The Treasure Island", "Fed") {}
}
