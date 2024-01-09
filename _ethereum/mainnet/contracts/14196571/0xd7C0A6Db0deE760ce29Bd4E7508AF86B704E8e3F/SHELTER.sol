
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shelter
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    immutable?    //
//                  //
//                  //
//////////////////////


contract SHELTER is ERC721Creator {
    constructor() ERC721Creator("Shelter", "SHELTER") {}
}
