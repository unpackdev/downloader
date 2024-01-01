// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Toon Punks Club
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    TPC#1    //
//             //
//             //
/////////////////


contract TPC is ERC721Creator {
    constructor() ERC721Creator("Toon Punks Club", "TPC") {}
}
