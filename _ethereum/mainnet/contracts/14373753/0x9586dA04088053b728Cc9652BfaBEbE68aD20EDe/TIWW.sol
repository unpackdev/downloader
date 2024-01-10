
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Teddycows in winter wonderland
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//      _______       _     _                                 //
//     |__   __|     | |   | |                                //
//        | | ___  __| | __| |_   _  ___ _____      _____     //
//        | |/ _ \/ _` |/ _` | | | |/ __/ _ \ \ /\ / / __|    //
//        | |  __/ (_| | (_| | |_| | (_| (_) \ V  V /\__ \    //
//        |_|\___|\__,_|\__,_|\__, |\___\___/ \_/\_/ |___/    //
//                             __/ |                          //
//                            |___/                           //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract TIWW is ERC721Creator {
    constructor() ERC721Creator("Teddycows in winter wonderland", "TIWW") {}
}
