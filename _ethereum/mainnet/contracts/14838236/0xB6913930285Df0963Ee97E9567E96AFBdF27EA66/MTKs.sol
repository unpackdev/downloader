
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mya Treasures Keys
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    Mya    //
//           //
//           //
///////////////


contract MTKs is ERC721Creator {
    constructor() ERC721Creator("Mya Treasures Keys", "MTKs") {}
}
