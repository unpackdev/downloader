
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fusion Elite
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    1337    //
//            //
//            //
////////////////


contract FE is ERC721Creator {
    constructor() ERC721Creator("Fusion Elite", "FE") {}
}
