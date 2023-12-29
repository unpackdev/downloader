// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Seasonal Symphonies
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//    .oOOOo.                                          o       .oOOOo.                        o                                    //
//    o     o                                         O        o     o                       O                  o                  //
//    O.                                              o        O.                            o                                     //
//     `OOoo.                                         O         `OOoo.                       O                                     //
//          `O .oOo. .oOoO' .oOo  .oOo. 'OoOo. .oOoO' o              `O O   o `oOOoOO. .oOo. OoOo. .oOo. 'OoOo. O  .oOo. .oOo      //
//           o OooO' O   o  `Ooo. O   o  o   O O   o  O               o o   O  O  o  o O   o o   o O   o  o   O o  OooO' `Ooo.     //
//    O.    .O O     o   O      O o   O  O   o o   O  o        O.    .O O   o  o  O  O o   O o   O o   O  O   o O  O         O     //
//     `oooO'  `OoO' `OoO'o `OoO' `OoO'  o   O `OoO'o Oo        `oooO'  `OoOO  O  o  o oOoO' O   o `OoO'  o   O o' `OoO' `OoO'     //
//                                                                          o          O                                           //
//                                                                       OoO'          o'                                          //
//                                                                                                                                 //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ss is ERC1155Creator {
    constructor() ERC1155Creator("Seasonal Symphonies", "ss") {}
}
