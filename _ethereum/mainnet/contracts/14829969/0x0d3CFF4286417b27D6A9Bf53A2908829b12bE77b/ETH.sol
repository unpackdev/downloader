
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: In The Shadows
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    ETH    //
//           //
//           //
///////////////


contract ETH is ERC721Creator {
    constructor() ERC721Creator("In The Shadows", "ETH") {}
}
