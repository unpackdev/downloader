// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stefano Contiero Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//    O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0    //
//    0                                                                        O    //
//    O                                                                        0    //
//    0                                                                        O    //
//    O                                                                        0    //
//    0                                                                        O    //
//    O                                  STEFAN                                0    //
//    0                                 CONTIERO                               O    //
//    O                                                                        0    //
//    0                                                                        O    //
//    O                                                                        0    //
//    0                                                                        O    //
//    O                                                                        0    //
//    0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O0O    //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


contract STFN is ERC1155Creator {
    constructor() ERC1155Creator("Stefano Contiero Editions", "STFN") {}
}
