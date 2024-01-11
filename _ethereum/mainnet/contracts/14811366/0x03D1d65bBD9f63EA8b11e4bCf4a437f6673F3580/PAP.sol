
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Psychedelics Anonymous Psilocybin
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    Psychedelics Anonymous Psilocybin    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract PAP is ERC721Creator {
    constructor() ERC721Creator("Psychedelics Anonymous Psilocybin", "PAP") {}
}
