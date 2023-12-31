
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Memory Palace
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                                                           //
//                                                                           //
//    .___  ___.  _______ .___  ___.   ______   .______     ____    ____     //
//    |   \/   | |   ____||   \/   |  /  __  \  |   _  \    \   \  /   /     //
//    |  \  /  | |  |__   |  \  /  | |  |  |  | |  |_)  |    \   \/   /      //
//    |  |\/|  | |   __|  |  |\/|  | |  |  |  | |      /      \_    _/       //
//    |  |  |  | |  |____ |  |  |  | |  `--'  | |  |\  \----.   |  |         //
//    |__|  |__| |_______||__|  |__|  \______/  | _| `._____|   |__|         //
//                                                                           //
//                                                                           //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////


contract MP is ERC721Creator {
    constructor() ERC721Creator("Memory Palace", "MP") {}
}
