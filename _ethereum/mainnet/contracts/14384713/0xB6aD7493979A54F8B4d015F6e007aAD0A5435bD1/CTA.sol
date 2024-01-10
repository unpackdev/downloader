
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CyberTrash n Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    CTA    //
//           //
//           //
///////////////


contract CTA is ERC721Creator {
    constructor() ERC721Creator("CyberTrash n Art", "CTA") {}
}
