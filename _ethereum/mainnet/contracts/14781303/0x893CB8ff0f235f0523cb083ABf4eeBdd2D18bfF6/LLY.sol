
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LilyLuna
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    LilyLuna    //
//                //
//                //
////////////////////


contract LLY is ERC721Creator {
    constructor() ERC721Creator("LilyLuna", "LLY") {}
}
