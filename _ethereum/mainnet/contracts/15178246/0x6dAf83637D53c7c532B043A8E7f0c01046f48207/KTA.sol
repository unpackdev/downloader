
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: kouki
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//                                 //
//    ██╗  ██╗████████╗ █████╗     //
//    ██║ ██╔╝╚══██╔══╝██╔══██╗    //
//    █████╔╝    ██║   ███████║    //
//    ██╔═██╗    ██║   ██╔══██║    //
//    ██║  ██╗   ██║   ██║  ██║    //
//    ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝    //
//                                 //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract KTA is ERC721Creator {
    constructor() ERC721Creator("kouki", "KTA") {}
}
