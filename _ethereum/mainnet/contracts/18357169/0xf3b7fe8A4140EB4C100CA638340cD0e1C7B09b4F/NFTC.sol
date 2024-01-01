// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NFT CAMPUS ERC-721
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    NFT CAMPUS ERC-721    //
//                          //
//                          //
//////////////////////////////


contract NFTC is ERC721Creator {
    constructor() ERC721Creator("NFT CAMPUS ERC-721", "NFTC") {}
}
