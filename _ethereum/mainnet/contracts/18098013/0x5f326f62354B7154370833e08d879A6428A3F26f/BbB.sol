// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Budapest by Belindalu
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//    ______           _                       _       //
//    | ___ \         | |                     | |      //
//    | |_/ /_   _  __| | __ _ _ __   ___  ___| |_     //
//    | ___ \ | | |/ _` |/ _` | '_ \ / _ \/ __| __|    //
//    | |_/ / |_| | (_| | (_| | |_) |  __/\__ \ |_     //
//    \____/ \__,_|\__,_|\__,_| .__/ \___||___/\__|    //
//                            | |                      //
//                            |_|                      //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract BbB is ERC1155Creator {
    constructor() ERC1155Creator("Budapest by Belindalu", "BbB") {}
}
