
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Witch Girls Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////
//         //
//         //
//    ✨    //
//         //
//         //
/////////////


contract WGC is ERC721Creator {
    constructor() ERC721Creator("Witch Girls Collection", "WGC") {}
}
