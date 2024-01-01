// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NFesmemorialNFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    nfes    //
//            //
//            //
////////////////


contract nf is ERC721Creator {
    constructor() ERC721Creator("NFesmemorialNFT", "nf") {}
}
