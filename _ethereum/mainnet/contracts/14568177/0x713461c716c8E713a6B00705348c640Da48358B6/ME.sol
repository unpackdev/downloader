
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MEDIA EMPIRE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//                                       //
//    ╔╦╗╔═╗╔╦╗╦╔═╗  ╔═╗╔╦╗╔═╗╦╦═╗╔═╗    //
//    ║║║║╣  ║║║╠═╣  ║╣ ║║║╠═╝║╠╦╝║╣     //
//    ╩ ╩╚═╝═╩╝╩╩ ╩  ╚═╝╩ ╩╩  ╩╩╚═╚═╝    //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract ME is ERC721Creator {
    constructor() ERC721Creator("MEDIA EMPIRE", "ME") {}
}
