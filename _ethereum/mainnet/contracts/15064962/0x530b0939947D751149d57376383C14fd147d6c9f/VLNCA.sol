
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Valencia
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//     _   _       _                 _           //
//    | | | |     | |               (_)          //
//    | | | | __ _| | ___ _ __   ___ _  __ _     //
//    | | | |/ _` | |/ _ \ '_ \ / __| |/ _` |    //
//    \ \_/ / (_| | |  __/ | | | (__| | (_| |    //
//     \___/ \__,_|_|\___|_| |_|\___|_|\__,_|    //
//                                               //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract VLNCA is ERC721Creator {
    constructor() ERC721Creator("Valencia", "VLNCA") {}
}
