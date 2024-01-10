
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cereal Club
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Cereal Club    //
//                   //
//                   //
///////////////////////


contract CC is ERC721Creator {
    constructor() ERC721Creator("Cereal Club", "CC") {}
}
