
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SUPERCARS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//    /////////////////////////////////////////////////////////////////////////////    //
//    //                                                                         //    //
//    //                                                                         //    //
//    //    .oOOOo.                             .oOOOo.                          //    //
//    //    o     o                            .O     o                          //    //
//    //    O.                                 o                                 //    //
//    //     `OOoo.                            o                                 //    //
//    //          `O O   o  .oOo. .oOo. `OoOo. o         .oOoO' `OoOo. .oOo      //    //
//    //           o o   O  O   o OooO'  o     O         O   o   o     `Ooo.     //    //
//    //    O.    .O O   o  o   O O      O     `o     .o o   O   O         O     //    //
//    //     `oooO'  `OoO'o oOoO' `OoO'  o      `OoooO'  `OoO'o  o     `OoO'     //    //
//    //                    O                                                    //    //
//    //                    o'                                                   //    //
//    //                                                                         //    //
//    //                                                                         //    //
//    /////////////////////////////////////////////////////////////////////////////    //
//                                                                                     //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract SUPERCARS is ERC721Creator {
    constructor() ERC721Creator("SUPERCARS", "SUPERCARS") {}
}
