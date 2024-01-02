// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Reflections
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    SRR    //
//           //
//           //
///////////////


contract SR is ERC721Creator {
    constructor() ERC721Creator("Reflections", "SR") {}
}
