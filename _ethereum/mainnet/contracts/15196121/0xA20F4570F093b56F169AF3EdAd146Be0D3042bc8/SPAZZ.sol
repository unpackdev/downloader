
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Spazz
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//                                                                            //
//                            db                        .dP' `Yb.             //
//                         db    db                   dP'      `Yb            //
//                                                               Yb           //
//    .d888b.  `Yb.d888b     'Yb     .aaa.    .aaa.    'Yb        Yb          //
//    8'   `Yb  88'    8Y     88    d'   `b  d'   `b    88       dPYb         //
//    Yb.   88  88     8P     88    `b.  .8  `b.  .8    88     ,dP  Yb        //
//        .dP   88   ,dP     .8P       .dP`b    .dP`b  .8P   .dP'    `Yb.     //
//      .dP'    88888888b.          .dP'  dP .dP'  dP                         //
//    .dP'      88                     .dP'     .dP'                          //
//             .8P                  .dP'     .dP'                             //
//                                                                            //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract SPAZZ is ERC721Creator {
    constructor() ERC721Creator("Spazz", "SPAZZ") {}
}
