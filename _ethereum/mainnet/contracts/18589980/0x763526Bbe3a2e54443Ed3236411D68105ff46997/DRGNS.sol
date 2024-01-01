// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: League of Dragons
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//    888b      88     ad88                                                                           //
//    8888b     88    d8"                                                                             //
//    88 `8b    88    88                                                                              //
//    88  `8b   88  MM88MMM  ,adPPYYba,  88,dPYba,,adPYba,    ,adPPYba,   88       88  ,adPPYba,      //
//    88   `8b  88    88     ""     `Y8  88P'   "88"    "8a  a8"     "8a  88       88  I8[    ""      //
//    88    `8b 88    88     ,adPPPPP88  88      88      88  8b       d8  88       88   `"Y8ba,       //
//    88     `8888    88     88,    ,88  88      88      88  "8a,   ,a8"  "8a,   ,a88  aa    ]8I      //
//    88      `888    88     `"8bbdP"Y8  88      88      88   `"YbbdP"'    `"YbbdP'Y8  `"YbbdP"'      //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DRGNS is ERC721Creator {
    constructor() ERC721Creator("League of Dragons", "DRGNS") {}
}
