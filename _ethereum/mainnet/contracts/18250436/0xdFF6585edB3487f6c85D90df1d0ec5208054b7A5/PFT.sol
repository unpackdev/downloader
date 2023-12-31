// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Profiler’s First Touch
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    092023    //
//              //
//              //
//////////////////


contract PFT is ERC721Creator {
    constructor() ERC721Creator(unicode"Profiler’s First Touch", "PFT") {}
}
