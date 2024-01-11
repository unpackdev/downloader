
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Parus bicolor
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                               //
//                                                                                                                                               //
//                                                                                                                                               //
//    88888888ba                                                      88           88                           88                               //
//    88      "8b                                                     88           ""                           88                               //
//    88      ,8P                                                     88                                        88                               //
//    88aaaaaa8P'  ,adPPYYba,  8b,dPPYba,  88       88  ,adPPYba,     88,dPPYba,   88   ,adPPYba,   ,adPPYba,   88   ,adPPYba,   8b,dPPYba,      //
//    88""""""'    ""     `Y8  88P'   "Y8  88       88  I8[    ""     88P'    "8a  88  a8"     ""  a8"     "8a  88  a8"     "8a  88P'   "Y8      //
//    88           ,adPPPPP88  88          88       88   `"Y8ba,      88       d8  88  8b          8b       d8  88  8b       d8  88              //
//    88           88,    ,88  88          "8a,   ,a88  aa    ]8I     88b,   ,a8"  88  "8a,   ,aa  "8a,   ,a8"  88  "8a,   ,a8"  88              //
//    88           `"8bbdP"Y8  88           `"YbbdP'Y8  `"YbbdP"'     8Y"Ybbd8"'   88   `"Ybbd8"'   `"YbbdP"'   88   `"YbbdP"'   88              //
//                                                                                                                                               //
//                                                                                                                                               //
//                                                                                                                                               //
//                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract bird is ERC721Creator {
    constructor() ERC721Creator("Parus bicolor", "bird") {}
}
