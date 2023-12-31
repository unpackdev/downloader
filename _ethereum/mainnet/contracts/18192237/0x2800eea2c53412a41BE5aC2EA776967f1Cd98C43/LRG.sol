// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LRG
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    Lion    //
//            //
//            //
////////////////


contract LRG is ERC721Creator {
    constructor() ERC721Creator("LRG", "LRG") {}
}
