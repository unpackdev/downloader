
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kaiju Mutants
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    Mutant Kaiju Kingz    //
//                          //
//                          //
//////////////////////////////


contract KM is ERC721Creator {
    constructor() ERC721Creator("Kaiju Mutants", "KM") {}
}
