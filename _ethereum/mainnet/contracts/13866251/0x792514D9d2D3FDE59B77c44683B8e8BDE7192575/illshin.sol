
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: illshin
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//           ■                                            //
//          ■       ■  ■          ■■         ■■           //
//         ■        ■■ ■           ■          ■■          //
//       ■■■        ■  ■        ■       ■      ■     ■    //
//      ■■■■        ■  ■         ■■     ■           ■■    //
//    ■■  ■■        ■  ■    ■          ■           ■■     //
//    ■   ■■        ■  ■   ■          ■           ■■      //
//        ■■       ■■  ■  ■■        ■■           ■■       //
//        ■■       ■   ■■■        ■■■          ■■■        //
//        ■■      ■     ■        ■■           ■           //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract illshin is ERC721Creator {
    constructor() ERC721Creator("illshin", "illshin") {}
}
