// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: UNTITLED COLLECTIVE Series 1 Drops
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    UNTITLED...    //
//                   //
//                   //
///////////////////////


contract UCS1D is ERC1155Creator {
    constructor() ERC1155Creator("UNTITLED COLLECTIVE Series 1 Drops", "UCS1D") {}
}
