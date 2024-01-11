
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: elements.
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//                                //
//    ╔═╗╦  ╔═╗╔╦╗╔═╗╔╗╔╔╦╗╔═╗    //
//    ║╣ ║  ║╣ ║║║║╣ ║║║ ║ ╚═╗    //
//    ╚═╝╩═╝╚═╝╩ ╩╚═╝╝╚╝ ╩ ╚═╝    //
//                                //
//                                //
//                                //
////////////////////////////////////


contract ELMNTS is ERC721Creator {
    constructor() ERC721Creator("elements.", "ELMNTS") {}
}
