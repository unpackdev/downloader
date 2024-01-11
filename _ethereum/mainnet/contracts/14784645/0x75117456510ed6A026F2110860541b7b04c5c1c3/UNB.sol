
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: unborn
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//    888  888 888  ,d8 d88PPPo 88888888   ,dbPPPp 888  ,d8     //
//    888  888 888_dPY8 888ooo8 888  888   d88ooP' 888_dPY8     //
//    888  888 8888' 88 888   8 888  888 ,88' P'   8888' 88     //
//    888PP888 Y8P   Y8 888PPPP 888oo888 88  do    Y8P   Y8     //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract UNB is ERC721Creator {
    constructor() ERC721Creator("unborn", "UNB") {}
}
