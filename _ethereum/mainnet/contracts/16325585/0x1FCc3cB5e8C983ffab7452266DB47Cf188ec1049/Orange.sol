
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Orangesekaii
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    Test    //
//            //
//            //
////////////////


contract Orange is ERC721Creator {
    constructor() ERC721Creator("Orangesekaii", "Orange") {}
}
