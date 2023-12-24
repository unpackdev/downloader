// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NWME
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//    -NW-ME-    //
//               //
//               //
///////////////////


contract NWME is ERC721Creator {
    constructor() ERC721Creator("NWME", "NWME") {}
}
