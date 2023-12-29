// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: medrezah
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    lfg to moon    //
//                   //
//                   //
///////////////////////


contract lfg is ERC1155Creator {
    constructor() ERC1155Creator("medrezah", "lfg") {}
}
