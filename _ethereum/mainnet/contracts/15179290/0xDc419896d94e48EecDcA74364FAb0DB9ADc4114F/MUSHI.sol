
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mushi
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    mushi mushi    //
//                   //
//                   //
///////////////////////


contract MUSHI is ERC721Creator {
    constructor() ERC721Creator("Mushi", "MUSHI") {}
}
