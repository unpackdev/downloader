// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Erika Rand Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//          E r i k a   R a n d          //
//                                       //
//               editions                //
//                                       //
//                                       //
///////////////////////////////////////////


contract EDITIONS is ERC1155Creator {
    constructor() ERC1155Creator("Erika Rand Editions", "EDITIONS") {}
}
