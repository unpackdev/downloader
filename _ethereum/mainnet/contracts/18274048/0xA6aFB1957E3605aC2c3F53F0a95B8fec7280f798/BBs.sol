// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BigBeard Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    BigBeard Editions    //
//                         //
//                         //
/////////////////////////////


contract BBs is ERC721Creator {
    constructor() ERC721Creator("BigBeard Editions", "BBs") {}
}
