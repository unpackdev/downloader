
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Homecoming II
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    HOMECOMING II    //
//                     //
//                     //
/////////////////////////


contract HOME is ERC721Creator {
    constructor() ERC721Creator("Homecoming II", "HOME") {}
}
