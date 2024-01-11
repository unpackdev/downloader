
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Tuning of the World
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    THE TUNING OF THE WORLD    //
//                               //
//                               //
///////////////////////////////////


contract WORLD is ERC721Creator {
    constructor() ERC721Creator("The Tuning of the World", "WORLD") {}
}
