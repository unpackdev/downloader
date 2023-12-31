// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Seasons
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    🌼 Seasons 🌼    //
//                     //
//                     //
/////////////////////////


contract SEASONS is ERC721Creator {
    constructor() ERC721Creator("Seasons", "SEASONS") {}
}
