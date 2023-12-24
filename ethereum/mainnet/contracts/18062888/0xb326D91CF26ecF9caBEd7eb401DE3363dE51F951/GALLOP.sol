// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GallopNFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    GALLOP MF    //
//                 //
//                 //
/////////////////////


contract GALLOP is ERC721Creator {
    constructor() ERC721Creator("GallopNFT", "GALLOP") {}
}
