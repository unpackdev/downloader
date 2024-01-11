
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DearVoilas
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//    888 88e                                         //
//    888 888b   ,e e,   ,"Y88b 888,8,                //
//    888 8888D d88 88b "8" 888 888 "                 //
//    888 888P  888   , ,ee 888 888                   //
//    888 88"    "YeeP" "88 888 888                   //
//                                                    //
//                                                    //
//    Y8b Y88888P           ,e, 888                   //
//     Y8b Y888P   e88 88e   "  888  ,"Y88b  dP"Y     //
//      Y8b Y8P   d888 888b 888 888 "8" 888 C88b      //
//       Y8b Y    Y888 888P 888 888 ,ee 888  Y88D     //
//        Y8P      "88 88"  888 888 "88 888 d,dP      //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract DEAR is ERC721Creator {
    constructor() ERC721Creator("DearVoilas", "DEAR") {}
}
