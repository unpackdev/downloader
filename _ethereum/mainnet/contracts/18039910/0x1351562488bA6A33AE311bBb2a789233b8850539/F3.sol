// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Flip3
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    ___________.__  .__      ________      //
//    \_   _____/|  | |__|_____\_____  \     //
//     |    __)  |  | |  \____ \ _(__  <     //
//     |     \   |  |_|  |  |_> >       \    //
//     \___  /   |____/__|   __/______  /    //
//         \/            |__|         \/     //
//                                           //
//                                           //
///////////////////////////////////////////////


contract F3 is ERC721Creator {
    constructor() ERC721Creator("Flip3", "F3") {}
}
