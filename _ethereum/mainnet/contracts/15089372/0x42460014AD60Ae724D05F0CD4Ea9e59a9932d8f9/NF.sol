
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Prueba
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    Collection    //
//                  //
//                  //
//////////////////////


contract NF is ERC721Creator {
    constructor() ERC721Creator("Prueba", "NF") {}
}
