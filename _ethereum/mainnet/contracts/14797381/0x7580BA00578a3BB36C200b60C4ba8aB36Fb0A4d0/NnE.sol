
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Newnotes Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    i love you all     //
//                       //
//                       //
///////////////////////////


contract NnE is ERC721Creator {
    constructor() ERC721Creator("Newnotes Editions", "NnE") {}
}
