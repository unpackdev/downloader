// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Movsum x Jesperish
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    Movsum x Jesperish        //
//    Collaboration Contract    //
//                              //
//                              //
//////////////////////////////////


contract MXJ is ERC721Creator {
    constructor() ERC721Creator("Movsum x Jesperish", "MXJ") {}
}
