
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 50mm Nihon
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//    50MM                                                               //
//    ooooo      ooo ooooo ooooo   ooooo   .oooooo.   ooooo      ooo     //
//    `888b.     `8' `888' `888'   `888'  d8P'  `Y8b  `888b.     `8'     //
//     8 `88b.    8   888   888     888  888      888  8 `88b.    8      //
//     8   `88b.  8   888   888ooooo888  888      888  8   `88b.  8      //
//     8     `88b.8   888   888     888  888      888  8     `88b.8      //
//     8       `888   888   888     888  `88b    d88'  8       `888      //
//    o8o        `8  o888o o888o   o888o  `Y8bood8P'  o8o        `8      //
//                                                    c.2016 — 2017      //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract NIHON is ERC721Creator {
    constructor() ERC721Creator("50mm Nihon", "NIHON") {}
}
