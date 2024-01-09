
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Still in Kansas
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                                          //
//     ██████╗ ██╗  ██╗██████╗ ██╗   ██╗    //
//    ██╔═████╗╚██╗██╔╝██╔══██╗╚██╗ ██╔╝    //
//    ██║██╔██║ ╚███╔╝ ██████╔╝ ╚████╔╝     //
//    ████╔╝██║ ██╔██╗ ██╔══██╗  ╚██╔╝      //
//    ╚██████╔╝██╔╝ ██╗██║  ██║   ██║       //
//     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝       //
//                                          //
//     0xry.com // Experiments in NFTs      //
//    0x: Still in Kansas by Ryan Edick     //
//                                          //
//                                          //
//////////////////////////////////////////////


contract KANSAS is ERC721Creator {
    constructor() ERC721Creator("Still in Kansas", "KANSAS") {}
}
