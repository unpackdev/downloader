
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: the Flowers project
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//      \   /  \   /  \   /  \   /  \   /        //
//    ---///----///----///----///----///---      //
//      /   \  /   \  /   \  /   \  /   \        //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract TFP is ERC721Creator {
    constructor() ERC721Creator("the Flowers project", "TFP") {}
}
