
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mask Cat
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    CAT    //
//           //
//           //
///////////////


contract CAT is ERC721Creator {
    constructor() ERC721Creator("Mask Cat", "CAT") {}
}
