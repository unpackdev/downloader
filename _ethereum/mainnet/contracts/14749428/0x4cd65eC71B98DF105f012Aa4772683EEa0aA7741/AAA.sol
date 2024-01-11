
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: My first NFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    First NFT mint    //
//                      //
//                      //
//////////////////////////


contract AAA is ERC721Creator {
    constructor() ERC721Creator("My first NFT", "AAA") {}
}
