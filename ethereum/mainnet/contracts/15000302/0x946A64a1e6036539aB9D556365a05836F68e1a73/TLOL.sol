
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Looks of Life
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Y.Lemondrip_NFT    //
//                       //
//                       //
///////////////////////////


contract TLOL is ERC721Creator {
    constructor() ERC721Creator("The Looks of Life", "TLOL") {}
}
