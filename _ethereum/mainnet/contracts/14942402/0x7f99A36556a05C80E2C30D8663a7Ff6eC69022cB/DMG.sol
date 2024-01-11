
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DotMaps Genesis
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    ######  #     #  #####      //
//    #     # ##   ## #     #     //
//    #     # # # # # #           //
//    #     # #  #  # #  ####     //
//    #     # #     # #     #     //
//    #     # #     # #     #     //
//    ######  #     #  #####      //
//                                //
//                                //
////////////////////////////////////


contract DMG is ERC721Creator {
    constructor() ERC721Creator("DotMaps Genesis", "DMG") {}
}
