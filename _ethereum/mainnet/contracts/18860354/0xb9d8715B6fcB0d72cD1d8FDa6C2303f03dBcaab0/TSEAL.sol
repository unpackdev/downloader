// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Turbo Seal
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    Turbo Seal    //
//                  //
//                  //
//////////////////////


contract TSEAL is ERC1155Creator {
    constructor() ERC1155Creator("Turbo Seal", "TSEAL") {}
}
