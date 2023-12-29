// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pollinators
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//    88888888ba               88  88  88                                                                           //
//    88      "8b              88  88  ""                             ,d                                            //
//    88      ,8P              88  88                                 88                                            //
//    88aaaaaa8P'  ,adPPYba,   88  88  88  8b,dPPYba,   ,adPPYYba,  MM88MMM  ,adPPYba,   8b,dPPYba,  ,adPPYba,      //
//    88""""""'   a8"     "8a  88  88  88  88P'   `"8a  ""     `Y8    88    a8"     "8a  88P'   "Y8  I8[    ""      //
//    88          8b       d8  88  88  88  88       88  ,adPPPPP88    88    8b       d8  88           `"Y8ba,       //
//    88          "8a,   ,a8"  88  88  88  88       88  88,    ,88    88,   "8a,   ,a8"  88          aa    ]8I      //
//    88           `"YbbdP"'   88  88  88  88       88  `"8bbdP"Y8    "Y888  `"YbbdP"'   88          `"YbbdP"'      //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LITSYPOLL1 is ERC721Creator {
    constructor() ERC721Creator("Pollinators", "LITSYPOLL1") {}
}
