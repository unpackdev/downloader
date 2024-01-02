// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Benefactor of the Arts
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    GOOD Marketplace          //
//    Benefactor of the Arts    //
//                              //
//                              //
//////////////////////////////////


contract GMBEN is ERC721Creator {
    constructor() ERC721Creator("Benefactor of the Arts", "GMBEN") {}
}
