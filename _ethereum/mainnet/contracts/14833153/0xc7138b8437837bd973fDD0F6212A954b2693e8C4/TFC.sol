
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Fuckles Collectibles
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    Collectibles for all!    //
//                             //
//                             //
/////////////////////////////////


contract TFC is ERC721Creator {
    constructor() ERC721Creator("The Fuckles Collectibles", "TFC") {}
}
