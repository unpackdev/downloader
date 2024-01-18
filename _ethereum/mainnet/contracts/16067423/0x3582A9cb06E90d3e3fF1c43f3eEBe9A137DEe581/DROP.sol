
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: moon drop
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    ☽ ✧    //
//           //
//           //
///////////////


contract DROP is ERC721Creator {
    constructor() ERC721Creator("moon drop", "DROP") {}
}
