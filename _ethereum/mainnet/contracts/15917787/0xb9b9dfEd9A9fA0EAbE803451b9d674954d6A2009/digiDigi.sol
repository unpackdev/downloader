
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: digidaigaku
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//        .___.__       .__     //
//      __| _/|__| ____ |__|    //
//     / __ | |  |/ ___\|  |    //
//    / /_/ | |  / /_/  >  |    //
//    \____ | |__\___  /|__|    //
//         \/   /_____/         //
//                              //
//                              //
//////////////////////////////////


contract digiDigi is ERC721Creator {
    constructor() ERC721Creator("digidaigaku", "digiDigi") {}
}
