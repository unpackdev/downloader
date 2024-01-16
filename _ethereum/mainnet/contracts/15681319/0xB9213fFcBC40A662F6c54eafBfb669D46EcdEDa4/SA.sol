
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SAPass
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    SquadAlpha    //
//                  //
//                  //
//////////////////////


contract SA is ERC721Creator {
    constructor() ERC721Creator("SAPass", "SA") {}
}
