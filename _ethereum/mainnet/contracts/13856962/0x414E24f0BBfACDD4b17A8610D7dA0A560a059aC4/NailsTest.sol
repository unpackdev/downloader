
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nails Test
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    PANDAMAN_NFT_CONTRACT    //
//                             //
//                             //
/////////////////////////////////


contract NailsTest is ERC721Creator {
    constructor() ERC721Creator("Nails Test", "NailsTest") {}
}
