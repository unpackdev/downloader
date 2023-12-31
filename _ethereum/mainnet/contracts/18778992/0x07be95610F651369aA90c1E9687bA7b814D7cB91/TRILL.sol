// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TRILL
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//     ____  __.________________________________         //
//    |    |/ _|\_   _____/\_   _____/\______   \        //
//    |      <   |    __)_  |    __)_  |     ___/        //
//    |    |  \  |        \ |        \ |    |            //
//    |____|__ \/_______  //_______  / |____|            //
//            \/        \/         \/                    //
//    .___ ___________                                   //
//    |   |\__    ___/                                   //
//    |   |  |    |                                      //
//    |   |  |    |                                      //
//    |___|  |____|                                      //
//                                                       //
//    _____________________ .___ .____     .____         //
//    \__    ___/\______   \|   ||    |    |    |        //
//      |    |    |       _/|   ||    |    |    |        //
//      |    |    |    |   \|   ||    |___ |    |___     //
//      |____|    |____|_  /|___||_______ \|_______ \    //
//                       \/              \/        \/    //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract TRILL is ERC1155Creator {
    constructor() ERC1155Creator("TRILL", "TRILL") {}
}
