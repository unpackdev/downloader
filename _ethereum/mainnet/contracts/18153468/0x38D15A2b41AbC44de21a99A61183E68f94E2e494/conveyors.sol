// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Conveyors
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    Conveyors    //
//                 //
//                 //
/////////////////////


contract conveyors is ERC721Creator {
    constructor() ERC721Creator("Conveyors", "conveyors") {}
}
