
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VOADORAS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                       ,d                                                            //
//                                                       88                                                            //
//     ,adPPYba,  8b,dPPYba,  8b       d8  8b,dPPYba,  MM88MMM  ,adPPYba,   8b,dPPYba,   8b       d8  8b,     ,d8      //
//    a8"     ""  88P'   "Y8  `8b     d8'  88P'    "8a   88    a8"     "8a  88P'    "8a  `8b     d8'   `Y8, ,8P'       //
//    8b          88           `8b   d8'   88       d8   88    8b       d8  88       d8   `8b   d8'      )888(         //
//    "8a,   ,aa  88            `8b,d8'    88b,   ,a8"   88,   "8a,   ,a8"  88b,   ,a8"    `8b,d8'     ,d8" "8b,       //
//     `"Ybbd8"'  88              Y88'     88`YbbdP"'    "Y888  `"YbbdP"'   88`YbbdP"'       Y88'     8P'     `Y8      //
//                                d8'      88                               88               d8'                       //
//                               d8'       88                               88              d8'                        //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VOA is ERC721Creator {
    constructor() ERC721Creator("VOADORAS", "VOA") {}
}
