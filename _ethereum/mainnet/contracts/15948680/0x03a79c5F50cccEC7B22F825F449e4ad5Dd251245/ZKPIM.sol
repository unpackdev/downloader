
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Paintings In Motion
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    PHYSICAL PAINTINGS IN ANALOG MOTION       //
//    ZAC KENNY (ART) x TIM RIOPELLE (MUSIC)    //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract ZKPIM is ERC721Creator {
    constructor() ERC721Creator("Paintings In Motion", "ZKPIM") {}
}
