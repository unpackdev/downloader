// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 4 season elementals
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Season of Fairies    //
//                         //
//                         //
/////////////////////////////


contract Se4 is ERC1155Creator {
    constructor() ERC1155Creator("4 season elementals", "Se4") {}
}
