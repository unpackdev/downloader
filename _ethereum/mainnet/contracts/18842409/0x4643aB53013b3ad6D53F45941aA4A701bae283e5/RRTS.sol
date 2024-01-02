// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rarities
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Busy_Signal    //
//    Rarities.      //
//                   //
//                   //
///////////////////////


contract RRTS is ERC721Creator {
    constructor() ERC721Creator("Rarities", "RRTS") {}
}
