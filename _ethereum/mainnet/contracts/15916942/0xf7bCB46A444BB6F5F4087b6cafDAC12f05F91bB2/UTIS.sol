
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Under The Italian Sun
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
//    88        88                        88                                      88                              //
//    88        88                        88                               ,d     88                              //
//    88        88                        88                               88     88                              //
//    88        88  8b,dPPYba,    ,adPPYb,88   ,adPPYba,  8b,dPPYba,     MM88MMM  88,dPPYba,    ,adPPYba,         //
//    88        88  88P'   `"8a  a8"    `Y88  a8P_____88  88P'   "Y8       88     88P'    "8a  a8P_____88         //
//    88        88  88       88  8b       88  8PP"""""""  88               88     88       88  8PP"""""""         //
//    Y8a.    .a8P  88       88  "8a,   ,d88  "8b,   ,aa  88               88,    88       88  "8b,   ,aa         //
//     `"Y8888Y"'   88       88   `"8bbdP"Y8   `"Ybbd8"'  88               "Y888  88       88   `"Ybbd8"'         //
//    88                       88  88                               ad88888ba                                     //
//    88    ,d                 88  ""                              d8"     "8b                                    //
//    88    88                 88                                  Y8,                                            //
//    88  MM88MMM  ,adPPYYba,  88  88  ,adPPYYba,  8b,dPPYba,      `Y8aaaaa,    88       88  8b,dPPYba,           //
//    88    88     ""     `Y8  88  88  ""     `Y8  88P'   `"8a       `"""""8b,  88       88  88P'   `"8a          //
//    88    88     ,adPPPPP88  88  88  ,adPPPPP88  88       88             `8b  88       88  88       88          //
//    88    88,    88,    ,88  88  88  88,    ,88  88       88     Y8a     a8P  "8a,   ,a88  88       88          //
//    88    "Y888  `"8bbdP"Y8  88  88  `"8bbdP"Y8  88       88      "Y88888P"    `"YbbdP'Y8  88       88          //
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract UTIS is ERC721Creator {
    constructor() ERC721Creator("Under The Italian Sun", "UTIS") {}
}
