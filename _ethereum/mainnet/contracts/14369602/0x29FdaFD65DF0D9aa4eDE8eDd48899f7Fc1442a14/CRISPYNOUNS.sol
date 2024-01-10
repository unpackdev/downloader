
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Crispy Nouns
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                         //
//                                                                                                                                                         //
//      .oooooo.   ooooooooo.   ooooo  .oooooo..o ooooooooo.   oooooo   oooo      ooooo      ooo   .oooooo.   ooooo     ooo ooooo      ooo  .oooooo..o     //
//     d8P'  `Y8b  `888   `Y88. `888' d8P'    `Y8 `888   `Y88.  `888.   .8'       `888b.     `8'  d8P'  `Y8b  `888'     `8' `888b.     `8' d8P'    `Y8     //
//    888           888   .d88'  888  Y88bo.       888   .d88'   `888. .8'         8 `88b.    8  888      888  888       8   8 `88b.    8  Y88bo.          //
//    888           888ooo88P'   888   `"Y8888o.   888ooo88P'     `888.8'          8   `88b.  8  888      888  888       8   8   `88b.  8   `"Y8888o.      //
//    888           888`88b.     888       `"Y88b  888             `888'           8     `88b.8  888      888  888       8   8     `88b.8       `"Y88b     //
//    `88b    ooo   888  `88b.   888  oo     .d8P  888              888            8       `888  `88b    d88'  `88.    .8'   8       `888  oo     .d8P     //
//     `Y8bood8P'  o888o  o888o o888o 8""88888P'  o888o            o888o          o8o        `8   `Y8bood8P'     `YbodP'    o8o        `8  8""88888P'      //
//                                                                                                                                                         //
//                                                                                                                                                         //
//                                                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CRISPYNOUNS is ERC721Creator {
    constructor() ERC721Creator("Crispy Nouns", "CRISPYNOUNS") {}
}
