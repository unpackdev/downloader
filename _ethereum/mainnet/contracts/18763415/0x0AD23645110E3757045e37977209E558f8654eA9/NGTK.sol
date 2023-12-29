// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NGTK-bits
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    oooo   oooo  ooooooo8 ooooooooooo oooo   oooo     //
//     8888o  88 o888    88 88  888  88  888  o88       //
//     88 888o88 888    oooo    888      888888         //
//     88   8888 888o    88     888      888  88o       //
//    o88o    88  888ooo888    o888o    o888o o888o     //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract NGTK is ERC1155Creator {
    constructor() ERC1155Creator("NGTK-bits", "NGTK") {}
}
