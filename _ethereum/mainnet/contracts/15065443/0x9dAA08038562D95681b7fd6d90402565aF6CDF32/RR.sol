
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Richie Rich
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//                                 //
//    ██████╗░░███████╗██████╗░    //
//    ██╔══██╗██╔██╔══╝██╔══██╗    //
//    ██████╔╝╚██████╗░██████╔╝    //
//    ██╔══██╗░╚═██╔██╗██╔══██╗    //
//    ██║░░██║███████╔╝██║░░██║    //
//    ╚═╝░░╚═╝╚══════╝░╚═╝░░╚═╝    //
//                                 //
//                                 //
/////////////////////////////////////


contract RR is ERC721Creator {
    constructor() ERC721Creator("Richie Rich", "RR") {}
}
