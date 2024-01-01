// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Planets Collection by Katty Banga
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    Send an art in my artstyle          //
//    the form of a list were written     //
//    by all                              //
//    those who somedays                  //
//    took part in the project            //
//                                        //
//                                        //
////////////////////////////////////////////


contract PlanetsKB is ERC721Creator {
    constructor() ERC721Creator("Planets Collection by Katty Banga", "PlanetsKB") {}
}
