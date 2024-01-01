// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Smells like Fire
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////
//           //
//           //
//    SLF    //
//           //
//           //
///////////////


contract SLF is ERC1155Creator {
    constructor() ERC1155Creator("Smells like Fire", "SLF") {}
}
