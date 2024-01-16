
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Happy Dog
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    //////////    //
//                  //
//                  //
//////////////////////


contract HD is ERC721Creator {
    constructor() ERC721Creator("Happy Dog", "HD") {}
}
