// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CINEM(AI)
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    1 seat, multiple choices – choose your destiny    //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract CINEMAI is ERC721Creator {
    constructor() ERC721Creator("CINEM(AI)", "CINEMAI") {}
}
