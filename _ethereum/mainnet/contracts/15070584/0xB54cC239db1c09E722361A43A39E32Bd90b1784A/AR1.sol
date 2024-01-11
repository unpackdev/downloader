
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Arman's 1/1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    I'm a 2d Animator,                                    //
//    I create loops, Infinite loops, Loops in the loops    //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract AR1 is ERC721Creator {
    constructor() ERC721Creator("Arman's 1/1", "AR1") {}
}
