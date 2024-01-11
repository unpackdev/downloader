
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RKNFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    Create with heart. Feel life, beauty and love.    //
//    I'm RK and welcome to my world.                   //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract RK is ERC721Creator {
    constructor() ERC721Creator("RKNFT", "RK") {}
}
