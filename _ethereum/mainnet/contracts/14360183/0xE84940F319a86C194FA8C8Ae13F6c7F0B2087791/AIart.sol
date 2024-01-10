
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AI artwork gallery
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    AI artwork gallery    //
//                          //
//                          //
//////////////////////////////


contract AIart is ERC721Creator {
    constructor() ERC721Creator("AI artwork gallery", "AIart") {}
}
