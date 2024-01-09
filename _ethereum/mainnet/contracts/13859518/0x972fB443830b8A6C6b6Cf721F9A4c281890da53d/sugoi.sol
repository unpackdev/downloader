
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: sugoi
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//          ■                ■                 //
//          ■        ■■■■■■ ■    ■             //
//    ■■■■■■■■■■        ■■       ■     ■■      //
//          ■          ■■        ■      ■      //
//       ■■■■                    ■       ■     //
//       ■  ■                    ■       ■     //
//       ■  ■       ■■           ■       ■■    //
//       ■■■■       ■            ■■  ■         //
//         ■■       ■■            ■ ■          //
//        ■■          ■■■■■■       ■■          //
//       ■                                     //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract sugoi is ERC721Creator {
    constructor() ERC721Creator("sugoi", "sugoi") {}
}
