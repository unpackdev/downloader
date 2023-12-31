// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Crypsybear
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//                                                                    //
//               ▒███▒                            ░███▓               //
//          ███████████████                  ███████████████▒         //
//       ▓████▒▒▒▒▒▒▒▒▒▒▒████▓             ████▒▒▒▒▒▒▒▒▒▒▒█████       //
//      ████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒████      //
//     ▒███▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█▒▒▒▒▒▒▒▒▒▒▒▒▒▒█▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒████     //
//     ▒███▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒████     //
//      ████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██████▓▒▒▒▒▒▒▒▒▒▒▒▒▓███      //
//       █████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██▒▒▒███▒▒▒▒▒▒▒▒▓████       //
//         ░████▒▒▒▒▒▒▒▒▒▒███▓███▒▒▒▒▒▒███▒▒███▒▒▒▒▒▒▒▒▒█████         //
//         ████▒▒▒▒▒▒▒▒▒▒▒▒█████▒▒▒▒▒▒▒██▒▒▒▒██▒▒▒▒▒▒▒▒▒▒████         //
//         ███▒▒▒▒▒▒▒▒▒▒▒▒██▒▒▒██▒▒▒▒▒▒▒▓█████▒▒▒▒▒▒▒▒▒▒▒▒███         //
//        ████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒████        //
//        ███▓▒▒▒▒▒▒▒▒▒▒▒████░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒███        //
//        ████▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░██████░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▓███        //
//        ▓███▒▒▒▒▒▒▒▒▒▒▒▒░░░░████████████░░░░▒▒▒▒▒▒▒▒▒▒▒▒███▓        //
//         ████▒▒▒▒▒▒▒▒▒▒▒░░░░░██████████░░░░░▒▒▒▒▒▒▒▒▒▒▒████         //
//          ████▒▒▒▒▒▒▒▒▒▒▒░░░░░░████░░░░░██░▒▒▒▒▒▒▒▒▒▒▒████          //
//           ████▒▒▒▒▒▒▒▒▒▒▒▒░░██░░░░█████░░▒▒▒▒▒▒▒▒▒▒▒████           //
//             ████▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒████             //
//               █████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█████               //
//                  ██████▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓██████                  //
//                      ████████████████████████                      //
//                              ░▓████▓░                              //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract CBEAR is ERC721Creator {
    constructor() ERC721Creator("Crypsybear", "CBEAR") {}
}
