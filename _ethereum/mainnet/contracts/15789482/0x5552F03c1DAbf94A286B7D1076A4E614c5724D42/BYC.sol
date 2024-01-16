
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Best Yacht Club
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    Best of the best NFT's    //
//                              //
//                              //
//////////////////////////////////


contract BYC is ERC721Creator {
    constructor() ERC721Creator("Best Yacht Club", "BYC") {}
}
