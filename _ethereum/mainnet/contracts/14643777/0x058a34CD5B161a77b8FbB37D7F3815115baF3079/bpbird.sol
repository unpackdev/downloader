
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: brainbirds
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    MFER    //
//            //
//            //
//            //
////////////////


contract bpbird is ERC721Creator {
    constructor() ERC721Creator("brainbirds", "bpbird") {}
}
