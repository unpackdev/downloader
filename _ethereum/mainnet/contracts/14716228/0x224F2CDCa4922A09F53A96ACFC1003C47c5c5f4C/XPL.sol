
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: XPLOIT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//    ██   ██ ██████  ██       ██████  ██ ████████     //
//     ██ ██  ██   ██ ██      ██    ██ ██    ██        //
//      ███   ██████  ██      ██    ██ ██    ██        //
//     ██ ██  ██      ██      ██    ██ ██    ██        //
//    ██   ██ ██      ███████  ██████  ██    ██        //
//                                                     //
//                                                     //
//    hello@xp.lo.it                                   //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract XPL is ERC721Creator {
    constructor() ERC721Creator("XPLOIT", "XPL") {}
}
