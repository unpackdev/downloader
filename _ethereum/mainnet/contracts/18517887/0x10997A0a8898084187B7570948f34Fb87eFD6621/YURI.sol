// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: YURI tarded
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////
//            //
//            //
//    YURI    //
//            //
//            //
////////////////


contract YURI is ERC1155Creator {
    constructor() ERC1155Creator("YURI tarded", "YURI") {}
}
