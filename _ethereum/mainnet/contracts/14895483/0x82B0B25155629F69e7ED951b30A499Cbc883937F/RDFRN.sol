
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Redfern's Garden
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//    `OooOOo.             o .oOo                     Oo                 //
//     o     `o           O  O                        oO                 //
//     O      O           o  o                         O                 //
//     o     .O           o  OoO                      o'                 //
//     OOooOO'  .oOo. .oOoO  o    .oOo. `OoOo. 'OoOo.    .oOo            //
//     o    o   OooO' o   O  O    OooO'  o      o   O    `Ooo.           //
//     O     O  O     O   o  o    O      O      O   o        O           //
//     O      o `OoO' `OoO'o O'   `OoO'  o      o   O    `OoO'           //
//                                                                       //
//                                                                       //
//     .oOOOo.                     o                                     //
//    .O     o                    O                                      //
//    o                           o                                      //
//    O                           o                                      //
//    O   .oOOo .oOoO' `OoOo. .oOoO  .oOo. 'OoOo.                        //
//    o.      O O   o   o     o   O  OooO'  o   O                        //
//     O.    oO o   O   O     O   o  O      O   o                        //
//      `OooO'  `OoO'o  o     `OoO'o `OoO'  o   O                        //
//                                                                       //
//                                                                       //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract RDFRN is ERC721Creator {
    constructor() ERC721Creator("Redfern's Garden", "RDFRN") {}
}
