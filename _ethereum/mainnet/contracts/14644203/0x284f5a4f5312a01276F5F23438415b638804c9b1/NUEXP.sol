
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NU EXPLORATIONS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//    ╔╗╔╦ ╦  ╔═╗═╗ ╦╔═╗╦  ╔═╗╦═╗╔═╗╔╦╗╦╔═╗╔╗╔╔═╗    //
//    ║║║║ ║  ║╣ ╔╩╦╝╠═╝║  ║ ║╠╦╝╠═╣ ║ ║║ ║║║║╚═╗    //
//    ╝╚╝╚═╝  ╚═╝╩ ╚═╩  ╩═╝╚═╝╩╚═╩ ╩ ╩ ╩╚═╝╝╚╝╚═╝    //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract NUEXP is ERC721Creator {
    constructor() ERC721Creator("NU EXPLORATIONS", "NUEXP") {}
}
