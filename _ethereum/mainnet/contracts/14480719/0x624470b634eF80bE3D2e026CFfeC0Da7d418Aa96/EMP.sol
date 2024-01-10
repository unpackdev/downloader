
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eric Melzer Photography
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//    ███████╗███╗   ███╗██████╗     //
//    ██╔════╝████╗ ████║██╔══██╗    //
//    █████╗  ██╔████╔██║██████╔╝    //
//    ██╔══╝  ██║╚██╔╝██║██╔═══╝     //
//    ███████╗██║ ╚═╝ ██║██║         //
//    ╚══════╝╚═╝     ╚═╝╚═╝         //
//                                   //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract EMP is ERC721Creator {
    constructor() ERC721Creator("Eric Melzer Photography", "EMP") {}
}
