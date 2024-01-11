
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ORB
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                 //
//                                                                                                 //
//    >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<     //
//    oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo     //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//                                       ╔═╗OO╦═╗OO╔╗O                                             //
//                                       ║O║OO╠╦╝OO╠╩╗                                             //
//                                       ╚═╝OO╩╚═OO╚═╝                                             //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//    ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo    //
//    <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>    //
//                                                                                                 //
//                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////


contract orb is ERC721Creator {
    constructor() ERC721Creator("ORB", "orb") {}
}
