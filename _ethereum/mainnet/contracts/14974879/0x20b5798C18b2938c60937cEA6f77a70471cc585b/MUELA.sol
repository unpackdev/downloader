
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ELAbyMikelUrmeneta
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    ELAbyMikelUrmeneta                   //
//    recaudación de fondos para el ELA    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract MUELA is ERC721Creator {
    constructor() ERC721Creator("ELAbyMikelUrmeneta", "MUELA") {}
}
