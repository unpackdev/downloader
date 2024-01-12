
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Duster+
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    The life of Pixels    //
//                          //
//                          //
//////////////////////////////


contract DTF is ERC721Creator {
    constructor() ERC721Creator("Duster+", "DTF") {}
}
