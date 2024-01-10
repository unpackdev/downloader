
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Visages de la Musique
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//     ▌ ▐·▪  .▄▄ ·  ▄▄▄·  ▄▄ • ▄▄▄ ..▄▄ ·     //
//    ▪█·█▌██ ▐█ ▀. ▐█ ▀█ ▐█ ▀ ▪▀▄.▀·▐█ ▀.     //
//    ▐█▐█•▐█·▄▀▀▀█▄▄█▀▀█ ▄█ ▀█▄▐▀▀▪▄▄▀▀▀█▄    //
//     ███ ▐█▌▐█▄▪▐█▐█ ▪▐▌▐█▄▪▐█▐█▄▄▌▐█▄▪▐█    //
//    . ▀  ▀▀▀ ▀▀▀▀  ▀  ▀ ·▀▀▀▀  ▀▀▀  ▀▀▀▀     //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract VISAGES is ERC721Creator {
    constructor() ERC721Creator("Visages de la Musique", "VISAGES") {}
}
