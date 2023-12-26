// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Burning Intern Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                    //
//                                                                                                                    //
//     888888ba                             oo                      oo            dP                                  //
//     88    `8b                                                                  88                                  //
//    a88aaaa8P' dP    dP 88d888b. 88d888b. dP 88d888b. .d8888b.    dP 88d888b. d8888P .d8888b. 88d888b. 88d888b.     //
//     88   `8b. 88    88 88'  `88 88'  `88 88 88'  `88 88'  `88    88 88'  `88   88   88ooood8 88'  `88 88'  `88     //
//     88    .88 88.  .88 88       88    88 88 88    88 88.  .88    88 88    88   88   88.  ... 88       88    88     //
//     88888888P `88888P' dP       dP    dP dP dP    dP `8888P88    dP dP    dP   dP   `88888P' dP       dP    dP     //
//    ooooooooooooooooooooooooooooooooooooooooooooooooooo~~~~.88~ooooooooooooooooooooooooooooooooooooooooooooooooo    //
//                                                       d8888P                                                       //
//                        dP                                                                                          //
//                        88                                                                                          //
//    .d8888b. 88d888b. d8888P                                                                                        //
//    88'  `88 88'  `88   88                                                                                          //
//    88.  .88 88         88                                                                                          //
//    `88888P8 dP         dP                                                                                          //
//    ooooooooooooooooooooooooo                                                                                       //
//                                                                                                                    //
//                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BIA is ERC721Creator {
    constructor() ERC721Creator("Burning Intern Art", "BIA") {}
}
