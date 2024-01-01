// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CryptoSimpunks
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    CryptoSimpunks    //
//                      //
//                      //
//////////////////////////


contract CSP is ERC721Creator {
    constructor() ERC721Creator("CryptoSimpunks", "CSP") {}
}
