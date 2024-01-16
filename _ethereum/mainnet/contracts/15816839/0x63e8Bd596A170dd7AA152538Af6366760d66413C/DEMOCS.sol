
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DEMOCS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    DemoCS    //
//              //
//              //
//////////////////


contract DEMOCS is ERC721Creator {
    constructor() ERC721Creator("DEMOCS", "DEMOCS") {}
}
