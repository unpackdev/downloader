
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: pepe
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    ________      //
//    \_____  \     //
//     /  ____/     //
//    /       \     //
//    \_______ \    //
//            \/    //
//                  //
//                  //
//////////////////////


contract pe is ERC721Creator {
    constructor() ERC721Creator("pepe", "pe") {}
}
