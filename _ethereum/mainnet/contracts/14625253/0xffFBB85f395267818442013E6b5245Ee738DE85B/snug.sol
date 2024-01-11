
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Snug
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//     _____ _____ _____ _____       //
//    |   __|   | |  |  |   __|      //
//    |__   | | | |  |  |  |  |_     //
//    |_____|_|___|_____|_____|_|    //
//                                   //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract snug is ERC721Creator {
    constructor() ERC721Creator("Snug", "snug") {}
}
