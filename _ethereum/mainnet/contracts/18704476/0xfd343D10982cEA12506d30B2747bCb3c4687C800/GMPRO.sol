// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Protector of the Arts
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    GOOD Marketplace         //
//    Protector of the Arts    //
//                             //
//                             //
/////////////////////////////////


contract GMPRO is ERC721Creator {
    constructor() ERC721Creator("Protector of the Arts", "GMPRO") {}
}
