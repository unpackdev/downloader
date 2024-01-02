// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Custodes
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    overwatching the odysseys    //
//                                 //
//                                 //
/////////////////////////////////////


contract OCO is ERC1155Creator {
    constructor() ERC1155Creator("Custodes", "OCO") {}
}
