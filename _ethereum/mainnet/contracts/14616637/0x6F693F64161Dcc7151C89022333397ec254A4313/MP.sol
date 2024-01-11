
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Metro Pass
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    Metro Pass    //
//                  //
//                  //
//////////////////////


contract MP is ERC721Creator {
    constructor() ERC721Creator("Metro Pass", "MP") {}
}
