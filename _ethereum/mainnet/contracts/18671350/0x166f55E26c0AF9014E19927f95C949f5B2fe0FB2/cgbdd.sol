// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chomperz Genesis
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                   //
//                                                                                                   //
//              oooo                                                                                 //
//              `888                                                                                 //
//     .ooooo.   888 .oo.    .ooooo.  ooo. .oo.  .oo.   oo.ooooo.   .ooooo.  oooo d8b   oooooooo     //
//    d88' `"Y8  888P"Y88b  d88' `88b `888P"Y88bP"Y88b   888' `88b d88' `88b `888""8P  d'""7d8P      //
//    888        888   888  888   888  888   888   888   888   888 888ooo888  888        .d8P'       //
//    888   .o8  888   888  888   888  888   888   888   888   888 888    .o  888      .d8P'  .P     //
//    `Y8bod8P' o888o o888o `Y8bod8P' o888o o888o o888o  888bod8P' `Y8bod8P' d888b    d8888888P      //
//                                                       888                                         //
//                                                      o888o                                        //
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////


contract cgbdd is ERC1155Creator {
    constructor() ERC1155Creator("Chomperz Genesis", "cgbdd") {}
}
