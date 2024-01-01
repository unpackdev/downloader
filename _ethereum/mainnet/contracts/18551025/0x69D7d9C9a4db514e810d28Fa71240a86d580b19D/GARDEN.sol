// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Garden Sunset
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    GARDEN    //
//              //
//              //
//////////////////


contract GARDEN is ERC721Creator {
    constructor() ERC721Creator("Garden Sunset", "GARDEN") {}
}
