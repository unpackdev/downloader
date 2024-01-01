// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Light and Shadow
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    ┓ ┳┓┏┓    //
//    ┃ ┃┃┗┓    //
//    ┗┛┛┗┗┛    //
//              //
//              //
//              //
//              //
//////////////////


contract LNS is ERC721Creator {
    constructor() ERC721Creator("Light and Shadow", "LNS") {}
}
