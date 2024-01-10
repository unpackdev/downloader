
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Toy Face
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    NFT «Toy Face»    //
//                      //
//                      //
//////////////////////////


contract TF is ERC721Creator {
    constructor() ERC721Creator("Toy Face", "TF") {}
}
