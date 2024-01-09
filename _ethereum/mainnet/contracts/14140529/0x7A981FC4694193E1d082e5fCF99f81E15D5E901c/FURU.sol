
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Karafuru NFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Karafuru NFT    //
//                    //
//                    //
////////////////////////


contract FURU is ERC721Creator {
    constructor() ERC721Creator("Karafuru NFT", "FURU") {}
}
