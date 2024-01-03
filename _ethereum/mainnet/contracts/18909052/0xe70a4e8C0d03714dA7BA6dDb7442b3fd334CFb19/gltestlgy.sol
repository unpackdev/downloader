// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: gltestlgy
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    gltestlgy    //
//                 //
//                 //
/////////////////////


contract gltestlgy is ERC1155Creator {
    constructor() ERC1155Creator("gltestlgy", "gltestlgy") {}
}
