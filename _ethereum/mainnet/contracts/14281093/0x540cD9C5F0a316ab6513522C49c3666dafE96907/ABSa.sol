
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ABSart
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    ABSart    //
//              //
//              //
//////////////////


contract ABSa is ERC721Creator {
    constructor() ERC721Creator("ABSart", "ABSa") {}
}
