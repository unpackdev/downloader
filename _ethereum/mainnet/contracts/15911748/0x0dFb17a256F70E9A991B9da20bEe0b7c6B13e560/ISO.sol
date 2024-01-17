
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Isolationist
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    ISO    //
//           //
//           //
///////////////


contract ISO is ERC721Creator {
    constructor() ERC721Creator("Isolationist", "ISO") {}
}
