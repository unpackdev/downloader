
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sunflowers for Peace
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//     ,888     8888    ,88'   8 8888                     //
//    888^8     8888   ,88'    8 8888                     //
//      8|8     8888  ,88'     8 8888                     //
//      8N8     8888 ,88'      8 8888                     //
//      8G8     888888<        8 8888                     //
//      8U8     8888 `MP.      8 8888                     //
//      8|8     8888   `JK.    8 8888                     //
//    /88888\   8888     `JO.  8888888888888              //
//                                                        //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract Ukraine is ERC721Creator {
    constructor() ERC721Creator("Sunflowers for Peace", "Ukraine") {}
}
