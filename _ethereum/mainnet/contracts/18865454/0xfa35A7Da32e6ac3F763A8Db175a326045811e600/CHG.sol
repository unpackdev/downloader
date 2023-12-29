// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Christmas gifts
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//    Christmas gift    //
//                      //
//                      //
//////////////////////////


contract CHG is ERC1155Creator {
    constructor() ERC1155Creator("Christmas gifts", "CHG") {}
}
