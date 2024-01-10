
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Python Bebop
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////
//          //
//          //
//    PB    //
//          //
//          //
//////////////


contract PB is ERC721Creator {
    constructor() ERC721Creator("Python Bebop", "PB") {}
}
