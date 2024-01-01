// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0xwlf
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////
//           //
//           //
//    WLF    //
//           //
//           //
///////////////


contract WLF is ERC1155Creator {
    constructor() ERC1155Creator("0xwlf", "WLF") {}
}
