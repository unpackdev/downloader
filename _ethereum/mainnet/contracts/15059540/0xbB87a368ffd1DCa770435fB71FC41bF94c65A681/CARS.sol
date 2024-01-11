
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cars: New York City, 1974-1976 by Langdon Clay
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    CARS: NEW YORK CITY, 1974-1976 BY LANGDON CLAY    //
//    IMAGES © LANGDON CLAY                             //
//    ALL RIGHTS RESERVED                               //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract CARS is ERC721Creator {
    constructor() ERC721Creator("Cars: New York City, 1974-1976 by Langdon Clay", "CARS") {}
}
