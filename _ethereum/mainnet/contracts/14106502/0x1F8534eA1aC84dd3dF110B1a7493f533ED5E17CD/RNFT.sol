
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ReggaeNFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    ReggaeNFT by Dasvibes.com    //
//                                 //
//                                 //
/////////////////////////////////////


contract RNFT is ERC721Creator {
    constructor() ERC721Creator("ReggaeNFT", "RNFT") {}
}
