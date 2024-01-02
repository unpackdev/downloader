// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FROG FIGHT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    FROG FIGHT    //
//                  //
//                  //
//////////////////////


contract FrogFight is ERC721Creator {
    constructor() ERC721Creator("FROG FIGHT", "FrogFight") {}
}
