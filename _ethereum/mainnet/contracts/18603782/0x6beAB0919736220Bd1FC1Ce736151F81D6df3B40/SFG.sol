// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sunflower girls collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    sunflower girls    //
//                       //
//                       //
///////////////////////////


contract SFG is ERC721Creator {
    constructor() ERC721Creator("Sunflower girls collection", "SFG") {}
}
