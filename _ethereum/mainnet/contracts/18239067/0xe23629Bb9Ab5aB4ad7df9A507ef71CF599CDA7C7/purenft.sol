// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: purenft
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////
//               //
//               //
//    purenft    //
//               //
//               //
///////////////////


contract purenft is ERC1155Creator {
    constructor() ERC1155Creator("purenft", "purenft") {}
}
