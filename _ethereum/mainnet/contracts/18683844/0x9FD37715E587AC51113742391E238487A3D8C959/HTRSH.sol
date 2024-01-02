// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Historic Trash
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    HstrkTrash    //
//                  //
//                  //
//////////////////////


contract HTRSH is ERC721Creator {
    constructor() ERC721Creator("Historic Trash", "HTRSH") {}
}
