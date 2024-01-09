
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RaidParty Heroes
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    RaidParty Heroes    //
//                        //
//                        //
////////////////////////////


contract HERO is ERC721Creator {
    constructor() ERC721Creator("RaidParty Heroes", "HERO") {}
}
