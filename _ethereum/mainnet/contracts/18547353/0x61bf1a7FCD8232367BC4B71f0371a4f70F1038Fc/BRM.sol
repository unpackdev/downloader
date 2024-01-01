// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Black Rose
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    Black Rose by melzieQ    //
//                             //
//                             //
/////////////////////////////////


contract BRM is ERC1155Creator {
    constructor() ERC1155Creator("Black Rose", "BRM") {}
}
