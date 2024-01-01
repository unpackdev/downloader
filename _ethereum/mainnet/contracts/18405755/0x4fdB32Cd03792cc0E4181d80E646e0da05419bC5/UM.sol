// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Unique Memories
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Unique Memories    //
//                       //
//                       //
///////////////////////////


contract UM is ERC721Creator {
    constructor() ERC721Creator("Unique Memories", "UM") {}
}
