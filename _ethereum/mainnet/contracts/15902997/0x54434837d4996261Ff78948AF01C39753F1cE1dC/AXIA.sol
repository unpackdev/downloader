
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AXIA
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    ██╗   ██╗ ██████╗ ██╗  ██╗    //
//    ╚██╗ ██╔╝██╔═══██╗██║  ██║    //
//     ╚████╔╝ ██║   ██║███████║    //
//      ╚██╔╝  ██║   ██║██╔══██║    //
//       ██║   ╚██████╔╝██║  ██║    //
//       ╚═╝    ╚═════╝ ╚═╝  ╚═╝    //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract AXIA is ERC721Creator {
    constructor() ERC721Creator("AXIA", "AXIA") {}
}
