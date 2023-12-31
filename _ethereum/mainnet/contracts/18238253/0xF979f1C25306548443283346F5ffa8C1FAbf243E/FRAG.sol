// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fragments
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//    88888888888                                                                                                       //
//    88                                                                                          ,d                    //
//    88                                                                                          88                    //
//    88aaaaa  8b,dPPYba,  ,adPPYYba,   ,adPPYb,d8  88,dPYba,,adPYba,    ,adPPYba,  8b,dPPYba,  MM88MMM  ,adPPYba,      //
//    88"""""  88P'   "Y8  ""     `Y8  a8"    `Y88  88P'   "88"    "8a  a8P_____88  88P'   `"8a   88     I8[    ""      //
//    88       88          ,adPPPPP88  8b       88  88      88      88  8PP"""""""  88       88   88      `"Y8ba,       //
//    88       88          88,    ,88  "8a,   ,d88  88      88      88  "8b,   ,aa  88       88   88,    aa    ]8I      //
//    88       88          `"8bbdP"Y8   `"YbbdP"Y8  88      88      88   `"Ybbd8"'  88       88   "Y888  `"YbbdP"'      //
//                                      aa,    ,88                                                                      //
//                                       "Y8bbdP"                                                                       //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FRAG is ERC721Creator {
    constructor() ERC721Creator("Fragments", "FRAG") {}
}
