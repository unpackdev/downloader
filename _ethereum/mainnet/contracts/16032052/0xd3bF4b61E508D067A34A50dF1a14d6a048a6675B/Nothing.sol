
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: I-Am-Nothing
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//    Nothing    //
//               //
//               //
///////////////////


contract Nothing is ERC721Creator {
    constructor() ERC721Creator("I-Am-Nothing", "Nothing") {}
}
