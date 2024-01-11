
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Candy Girls
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    Candy Girls collection by Elena Ali    //
//                                           //
//                                           //
///////////////////////////////////////////////


contract CG is ERC721Creator {
    constructor() ERC721Creator("Candy Girls", "CG") {}
}
