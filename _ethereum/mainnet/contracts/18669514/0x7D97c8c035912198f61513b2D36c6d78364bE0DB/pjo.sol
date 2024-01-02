// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PjoArt
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    pjo    //
//           //
//           //
///////////////


contract pjo is ERC721Creator {
    constructor() ERC721Creator("PjoArt", "pjo") {}
}
