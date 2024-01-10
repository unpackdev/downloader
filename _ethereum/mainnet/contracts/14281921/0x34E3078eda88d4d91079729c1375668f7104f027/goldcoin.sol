
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gold coin
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//    ooooo      oooooooooooooooooooooooooooo    .oooooo.    .oooooo.  ooooo       ooooo       oooooooooooo  .oooooo.  ooooooooooooo  .oooooo.  ooooooooo.      //
//    `888b.     `8'`888'     `88'   888   `8   d8P'  `Y8b  d8P'  `Y8b `888'       `888'       `888'     `8 d8P'  `Y8b 8'   888   `8 d8P'  `Y8b `888   `Y88.    //
//     8 `88b.    8  888             888       888         888      888 888         888         888        888              888     888      888 888   .d88'    //
//     8   `88b.  8  888oooo8        888       888         888      888 888         888         888oooo8   888              888     888      888 888ooo88P'     //
//     8     `88b.8  888    "        888       888         888      888 888         888         888    "   888              888     888      888 888`88b.       //
//     8       `888  888             888       `88b    ooo `88b    d88' 888       o 888       o 888       o`88b    ooo      888     `88b    d88' 888  `88b.     //
//    o8o        `8 o888o           o888o       `Y8bood8P'  `Y8bood8P' o888ooooood8o888ooooood8o888ooooood8 `Y8bood8P'     o888o     `Y8bood8P' o888o  o888o    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//    ooooo      oooooooo oooooooooooo  .oooooo.     oooooooooooooooooooooooooooooo   ooooo                                                                     //
//    `888b.     `8'`888'd'""""""d888' d8P'  `Y8b    `888'     `88'   888   `8`888'   `888'                                                                     //
//     8 `88b.    8  888       .888P  888      888    888             888      888     888                                                                      //
//     8   `88b.  8  888      d888'   888      888    888oooo8        888      888ooooo888                                                                      //
//     8     `88b.8  888    .888P     888      888    888    "        888      888     888                                                                      //
//     8       `888  888   d888'    .P`88b    d88'.o. 888       o     888      888     888                                                                      //
//    o8o        `8 o888o.8888888888P  `Y8bood8P' Y8Po888ooooood8    o888o    o888o   o888o                                                                     //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract goldcoin is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
