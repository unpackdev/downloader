
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: David Rees
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//      __ \                 _)      |       _ \                        //
//      |   |   _` | \ \   /  |   _` |      |   |   _ \   _ \   __|     //
//      |   |  (   |  \ \ /   |  (   |      __ <    __/   __/ \__ \     //
//     ____/  \__,_|   \_/   _| \__,_|     _| \_\ \___| \___| ____/     //
//                                                                      //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract DR is ERC721Creator {
    constructor() ERC721Creator("David Rees", "DR") {}
}
