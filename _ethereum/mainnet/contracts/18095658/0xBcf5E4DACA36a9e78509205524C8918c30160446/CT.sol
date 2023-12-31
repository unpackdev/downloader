// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Childhood trauma
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////
//          //
//          //
//    CT    //
//          //
//          //
//////////////


contract CT is ERC721Creator {
    constructor() ERC721Creator("Childhood trauma", "CT") {}
}
