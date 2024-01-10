
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Natural Energy Force
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                             //
//                                                                                                             //
//    ooooo      ooo       .o.       ooooooooooooo ooooo     ooo ooooooooo.         .o.       ooooo            //
//    `888b.     `8'      .888.      8'   888   `8 `888'     `8' `888   `Y88.      .888.      `888'            //
//     8 `88b.    8      .8"888.          888       888       8   888   .d88'     .8"888.      888             //
//     8   `88b.  8     .8' `888.         888       888       8   888ooo88P'     .8' `888.     888             //
//     8     `88b.8    .88ooo8888.        888       888       8   888`88b.      .88ooo8888.    888             //
//     8       `888   .8'     `888.       888       `88.    .8'   888  `88b.   .8'     `888.   888       o     //
//    o8o        `8  o88o     o8888o     o888o        `YbodP'    o888o  o888o o88o     o8888o o888ooooood8     //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//              oooooooooooo ooooo      ooo oooooooooooo ooooooooo.     .oooooo.    oooooo   oooo              //
//              `888'     `8 `888b.     `8' `888'     `8 `888   `Y88.  d8P'  `Y8b    `888.   .8'               //
//               888          8 `88b.    8   888          888   .d88' 888             `888. .8'                //
//               888oooo8     8   `88b.  8   888oooo8     888ooo88P'  888              `888.8'                 //
//               888    "     8     `88b.8   888    "     888`88b.    888     ooooo     `888'                  //
//               888       o  8       `888   888       o  888  `88b.  `88.    .88'       888                   //
//              o888ooooood8 o8o        `8  o888ooooood8 o888o  o888o  `Y8bood8P'       o888o                  //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                   oooooooooooo   .oooooo.   ooooooooo.     .oooooo.   oooooooooooo                          //
//                   `888'     `8  d8P'  `Y8b  `888   `Y88.  d8P'  `Y8b  `888'     `8                          //
//                    888         888      888  888   .d88' 888           888                                  //
//                    888oooo8    888      888  888ooo88P'  888           888oooo8                             //
//                    888    "    888      888  888`88b.    888           888    "                             //
//                    888         `88b    d88'  888  `88b.  `88b    ooo   888       o                          //
//                   o888o         `Y8bood8P'  o888o  o888o  `Y8bood8P'  o888ooooood8                          //
//                                                                                                             //
//                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NEF is ERC721Creator {
    constructor() ERC721Creator("Natural Energy Force", "NEF") {}
}
