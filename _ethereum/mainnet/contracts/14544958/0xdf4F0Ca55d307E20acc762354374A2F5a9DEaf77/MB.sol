
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Moonbirds
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    Moonbirds    //
//                 //
//                 //
/////////////////////


contract MB is ERC721Creator {
    constructor() ERC721Creator("Moonbirds", "MB") {}
}
