
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 1/1's
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    beaudenison.eth    //
//                       //
//                       //
///////////////////////////


contract One is ERC721Creator {
    constructor() ERC721Creator("1/1's", "One") {}
}
