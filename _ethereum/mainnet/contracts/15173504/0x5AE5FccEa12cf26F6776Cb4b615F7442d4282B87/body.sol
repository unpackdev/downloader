
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cold on Hot
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    Cold on Hot    //
//                   //
//                   //
///////////////////////


contract body is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
