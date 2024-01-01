// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Reborn - Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////
//                          //
//                          //
//    We are all reborn     //
//                          //
//                          //
//////////////////////////////


contract Rbrn is ERC1155Creator {
    constructor() ERC1155Creator("Reborn - Editions", "Rbrn") {}
}
