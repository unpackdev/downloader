// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Resin Art Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    RAC    //
//           //
//           //
///////////////


contract RAC is ERC721Creator {
    constructor() ERC721Creator("Resin Art Collection", "RAC") {}
}
