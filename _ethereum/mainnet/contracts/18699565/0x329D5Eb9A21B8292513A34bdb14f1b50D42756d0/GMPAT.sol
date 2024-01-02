// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Patron of the Arts
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    GOOD Marketplace      //
//    Patron of the Arts    //
//                          //
//                          //
//////////////////////////////


contract GMPAT is ERC721Creator {
    constructor() ERC721Creator("Patron of the Arts", "GMPAT") {}
}
