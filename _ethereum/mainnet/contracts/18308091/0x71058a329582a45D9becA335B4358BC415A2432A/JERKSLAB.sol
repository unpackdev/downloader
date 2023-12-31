// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JERKS LAB
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                  //
//                                                                                                                  //
//       oooo oooooooooooo ooooooooo.   oooo    oooo  .oooooo..o      ooooo              .o.       oooooooooo.      //
//       `888 `888'     `8 `888   `Y88. `888   .8P'  d8P'    `Y8      `888'             .888.      `888'   `Y8b     //
//        888  888          888   .d88'  888  d8'    Y88bo.            888             .8"888.      888     888     //
//        888  888oooo8     888ooo88P'   88888[       `"Y8888o.        888            .8' `888.     888oooo888'     //
//        888  888    "     888`88b.     888`88b.         `"Y88b       888           .88ooo8888.    888    `88b     //
//        888  888       o  888  `88b.   888  `88b.  oo     .d8P       888       o  .8'     `888.   888    .88P     //
//    .o. 88P o888ooooood8 o888o  o888o o888o  o888o 8""88888P'       o888ooooood8 o88o     o8888o o888bood8P'      //
//    `Y888P                                                                                                        //
//                                                                                                                  //
//                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JERKSLAB is ERC1155Creator {
    constructor() ERC1155Creator("JERKS LAB", "JERKSLAB") {}
}
