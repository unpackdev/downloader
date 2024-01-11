
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nagy Zoltán Péter
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    NZP    //
//           //
//           //
///////////////


contract NZP is ERC721Creator {
    constructor() ERC721Creator(unicode"Nagy Zoltán Péter", "NZP") {}
}
