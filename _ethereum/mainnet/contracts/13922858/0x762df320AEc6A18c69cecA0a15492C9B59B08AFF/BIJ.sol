
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bijan's NFTs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    shah256-forever    //
//                       //
//                       //
///////////////////////////


contract BIJ is ERC721Creator {
    constructor() ERC721Creator("Bijan's NFTs", "BIJ") {}
}
