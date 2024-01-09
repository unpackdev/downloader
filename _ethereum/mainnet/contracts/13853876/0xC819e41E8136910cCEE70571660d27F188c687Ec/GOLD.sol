
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OPlerou
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//      ,ad8888ba,     d8' 88888888ba  88                                                     //
//     d8"'    `"8b   d8'  88      "8b 88        88                                           //
//    d8'        `8b ""    88      ,8P 88     888                                             //
//    88          88       88aaaaaa8P' 88  ,adPPYba, 8b,dPPYba,  ,adPPYba,  88       88       //
//    88          88       88""""""'   88 a8P_____88 88P'   "Y8 a8"     "8a 88       88       //
//    Y8,        ,8P       88          88 8PP""""""" 88         8b       d8 88       88       //
//     Y8a.    .a8P        88          88 "8b,   ,aa 88         "8a,   ,a8" "8a,   ,a88       //
//      `"Y8888Y"'         88          88  `"Ybbd8"' 88          `"YbbdP"'   `"YbbdP'Y8       //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract GOLD is ERC721Creator {
    constructor() ERC721Creator("OPlerou", "GOLD") {}
}
