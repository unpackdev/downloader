// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PEPEINK
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    PEPEINK.FUN    //
//                   //
//                   //
///////////////////////


contract PEPEINK is ERC1155Creator {
    constructor() ERC1155Creator("PEPEINK", "PEPEINK") {}
}
