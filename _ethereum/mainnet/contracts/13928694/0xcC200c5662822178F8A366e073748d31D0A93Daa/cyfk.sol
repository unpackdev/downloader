
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CyberFreaks
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//      _____     __           ____             __          //
//     / ___/_ __/ /  ___ ____/ __/______ ___ _/ /__ ___    //
//    / /__/ // / _ \/ -_) __/ _// __/ -_) _ `/  '_/(_-<    //
//    \___/\_, /_.__/\__/_/ /_/ /_/  \__/\_,_/_/\_\/___/    //
//        /___/                                             //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract cyfk is ERC721Creator {
    constructor() ERC721Creator("CyberFreaks", "cyfk") {}
}
