// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tiny Puter Pals
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    TINYPP    //
//              //
//              //
//////////////////


contract TINYPP is ERC721Creator {
    constructor() ERC721Creator("Tiny Puter Pals", "TINYPP") {}
}
