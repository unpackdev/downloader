// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Crystallo
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    Crystallo    //
//                 //
//                 //
/////////////////////


contract CRYST is ERC721Creator {
    constructor() ERC721Creator("Crystallo", "CRYST") {}
}
