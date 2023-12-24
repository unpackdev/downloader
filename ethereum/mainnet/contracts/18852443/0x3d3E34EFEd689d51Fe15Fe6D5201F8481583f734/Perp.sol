// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Perpendicular
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    ROM    //
//           //
//           //
///////////////


contract Perp is ERC721Creator {
    constructor() ERC721Creator("Perpendicular", "Perp") {}
}
