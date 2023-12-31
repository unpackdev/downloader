// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Papros. Indian summer
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//    Artist: PAPROS                                                     //
//    Medium: photography                                                //
//    Art movement: Abstract photography                                 //
//    Technique: Light painting                                          //
//                                                                       //
//    “I love Indian summer with its warm golden colors.                 //
//    This time gives rise to some kind of positive nostalgia in me,     //
//    guiding me through the cloudy corners of my memory                 //
//    and throwing happy moments of my life into my consciousness”       //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract PAPRIS is ERC721Creator {
    constructor() ERC721Creator("Papros. Indian summer", "PAPRIS") {}
}
