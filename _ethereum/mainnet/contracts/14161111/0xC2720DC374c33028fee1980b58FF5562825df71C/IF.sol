
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Invisible Friends
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Invisible Friends    //
//                         //
//                         //
/////////////////////////////


contract IF is ERC721Creator {
    constructor() ERC721Creator("Invisible Friends", "IF") {}
}
