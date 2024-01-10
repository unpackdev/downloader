
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Monty Python Bebop
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    MPB    //
//           //
//           //
///////////////


contract MPB is ERC721Creator {
    constructor() ERC721Creator("Monty Python Bebop", "MPB") {}
}
