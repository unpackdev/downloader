// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Didier RA
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////
//                          //
//                          //
//    ART IS EXPLORATION    //
//                          //
//                          //
//////////////////////////////


contract RA is ERC1155Creator {
    constructor() ERC1155Creator("Didier RA", "RA") {}
}
