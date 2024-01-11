
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Aiko Relics
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                               //
//                                                                                                               //
//          .o.        o8o  oooo                       ooooooooo.             oooo   o8o                         //
//         .888.       `"'  `888                       `888   `Y88.           `888   `"'                         //
//        .8"888.     oooo   888  oooo   .ooooo.        888   .d88'  .ooooo.   888  oooo   .ooooo.   .oooo.o     //
//       .8' `888.    `888   888 .8P'   d88' `88b       888ooo88P'  d88' `88b  888  `888  d88' `"Y8 d88(  "8     //
//      .88ooo8888.    888   888888.    888   888       888`88b.    888ooo888  888   888  888       `"Y88b.      //
//     .8'     `888.   888   888 `88b.  888   888       888  `88b.  888    .o  888   888  888   .o8 o.  )88b     //
//    o88o     o8888o o888o o888o o888o `Y8bod8P'      o888o  o888o `Y8bod8P' o888o o888o `Y8bod8P' 8""888P'     //
//                                                                                                               //
//                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AIKO is ERC721Creator {
    constructor() ERC721Creator("Aiko Relics", "AIKO") {}
}
