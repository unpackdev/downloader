
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tiny Tin
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    Tin    //
//           //
//           //
///////////////


contract Tin is ERC721Creator {
    constructor() ERC721Creator("Tiny Tin", "Tin") {}
}
