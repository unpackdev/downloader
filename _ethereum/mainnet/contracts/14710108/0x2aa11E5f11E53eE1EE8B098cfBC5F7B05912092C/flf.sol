
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: felafel
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//    felafel    //
//               //
//               //
///////////////////


contract flf is ERC721Creator {
    constructor() ERC721Creator("felafel", "flf") {}
}
