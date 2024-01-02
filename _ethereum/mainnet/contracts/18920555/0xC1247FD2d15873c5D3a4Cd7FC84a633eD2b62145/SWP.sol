// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Steamboat Willie Pixel
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    SWP    //
//           //
//           //
///////////////


contract SWP is ERC721Creator {
    constructor() ERC721Creator("Steamboat Willie Pixel", "SWP") {}
}
