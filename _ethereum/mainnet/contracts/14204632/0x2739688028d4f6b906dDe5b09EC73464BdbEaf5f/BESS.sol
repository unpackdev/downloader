
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BESSFRENS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    ╔╗ ╔═╗╔═╗╔═╗╔═╗╦═╗╔═╗╔╗╔╔═╗    //
//    ╠╩╗║╣ ╚═╗╚═╗╠╣ ╠╦╝║╣ ║║║╚═╗    //
//    ╚═╝╚═╝╚═╝╚═╝╚  ╩╚═╚═╝╝╚╝╚═╝    //
//                                   //
//                                   //
///////////////////////////////////////


contract BESS is ERC721Creator {
    constructor() ERC721Creator("BESSFRENS", "BESS") {}
}
