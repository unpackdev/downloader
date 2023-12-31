// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: momi MOMI
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    momi MOMI    //
//                 //
//                 //
/////////////////////


contract momi is ERC721Creator {
    constructor() ERC721Creator("momi MOMI", "momi") {}
}
