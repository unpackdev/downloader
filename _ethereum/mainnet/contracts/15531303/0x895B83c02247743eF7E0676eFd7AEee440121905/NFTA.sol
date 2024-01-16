
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test NFT - Artist
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    Tst    //
//           //
//           //
///////////////


contract NFTA is ERC721Creator {
    constructor() ERC721Creator("Test NFT - Artist", "NFTA") {}
}
