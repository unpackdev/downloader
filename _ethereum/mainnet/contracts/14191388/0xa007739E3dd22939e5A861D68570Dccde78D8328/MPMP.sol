
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Meta Punk
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    Meta Punk    //
//    Mint Pass    //
//                 //
//                 //
/////////////////////


contract MPMP is ERC721Creator {
    constructor() ERC721Creator("Meta Punk", "MPMP") {}
}
