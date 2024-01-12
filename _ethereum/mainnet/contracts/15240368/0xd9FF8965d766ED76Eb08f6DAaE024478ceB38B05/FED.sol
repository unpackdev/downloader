
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HDRome
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
/////////////////////////////////////////////


contract FED is ERC721Creator {
    constructor() ERC721Creator("HDRome", "FED") {}
}
