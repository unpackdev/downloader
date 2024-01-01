// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cosmic Pantheon
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    COSMIC PANTHEON 🪐    //
//                          //
//                          //
//////////////////////////////


contract COSMIC is ERC721Creator {
    constructor() ERC721Creator("Cosmic Pantheon", "COSMIC") {}
}
