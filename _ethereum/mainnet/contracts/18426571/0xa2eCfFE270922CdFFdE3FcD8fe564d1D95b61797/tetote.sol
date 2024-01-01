// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TeToTe
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    tetote    //
//              //
//              //
//////////////////


contract tetote is ERC721Creator {
    constructor() ERC721Creator("TeToTe", "tetote") {}
}
