// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: kernalburn
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    kburn test    //
//                  //
//                  //
//////////////////////


contract kburn is ERC1155Creator {
    constructor() ERC1155Creator("kernalburn", "kburn") {}
}
