// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bottle Cap Guitar Freaks
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                                         //
//    ██████╗  ██████╗ ██████╗ ███████╗    //
//    ██╔══██╗██╔════╝██╔════╝ ██╔════╝    //
//    ██████╔╝██║     ██║  ███╗█████╗      //
//    ██╔══██╗██║     ██║   ██║██╔══╝      //
//    ██████╔╝╚██████╗╚██████╔╝██║         //
//    ╚═════╝  ╚═════╝ ╚═════╝ ╚═╝         //
//                                         //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract BCGF is ERC721Creator {
    constructor() ERC721Creator("Bottle Cap Guitar Freaks", "BCGF") {}
}
