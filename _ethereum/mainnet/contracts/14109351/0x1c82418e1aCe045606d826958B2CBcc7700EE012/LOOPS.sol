
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Loopiverse
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//       __                   _                             //
//      / /  ___   ___  _ __ (_)_   _____ _ __ ___  ___     //
//     / /  / _ \ / _ \|  _ \| \ \ / / _ \  __/ __|/ _ \    //
//    / /__| (_) | (_) | |_) | |\ V /  __/ |  \__ \  __/    //
//    \____/\___/ \___/|  __/|_| \_/ \___|_|  |___/\___|    //
//                     |_|                                  //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract LOOPS is ERC721Creator {
    constructor() ERC721Creator("Loopiverse", "LOOPS") {}
}
