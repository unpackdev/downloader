
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: aimojis
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    aimojis by collin.eth    //
//                             //
//                             //
/////////////////////////////////


contract aimoji is ERC721Creator {
    constructor() ERC721Creator("aimojis", "aimoji") {}
}
