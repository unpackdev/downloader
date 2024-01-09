
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Deadfrenz
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    Deadfrenz    //
//                 //
//                 //
/////////////////////


contract DEAD is ERC721Creator {
    constructor() ERC721Creator("Deadfrenz", "DEAD") {}
}
