
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Southside City Artifacts
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                     |                       //
//                     |.|                     //
//                     |.|                     //
//                    |\./|                    //
//                    |\./|                    //
//    .               |\./|               .    //
//     \^.\          |\\.//|          /.^/     //
//      \--.|\       |\\.//|       /|.--/      //
//        \--.| \    |\\.//|    / |.--/        //
//         \---.|\    |\./|    /|.---/         //
//            \--.|\  |\./|  /|.--/            //
//               \ .\  |.|  /. /               //
//     _ -_^_^_^_-  \ \\ // /  -_^_^_^_- _     //
//       - -/_/_/- ^ ^  |  ^ ^ -\_\_\- -       //
//                                             //
//                                             //
//     SMOKE WEED AND LIVE IT UP SSC STYLE     //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract SSCA is ERC721Creator {
    constructor() ERC721Creator("Southside City Artifacts", "SSCA") {}
}
