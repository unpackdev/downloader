
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PlanetSLY
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                     //
//                                                                                                     //
//    SLYGuys punching the Ethereum blockchain in the face. @theslystallone official NFT project 🥊    //
//                                                                                                     //
//                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SLY is ERC721Creator {
    constructor() ERC721Creator("PlanetSLY", "SLY") {}
}
