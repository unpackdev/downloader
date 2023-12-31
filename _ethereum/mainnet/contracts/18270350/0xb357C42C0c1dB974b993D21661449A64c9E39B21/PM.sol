// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: procedural motion
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//      __   __             __                      //
//     /    /  |      /    /    /                   //
//    (___ (___| ___ (___ ( __    ___  ___          //
//        )|   )|   )|    |   )| |   )|___ \   )    //
//     __/ |__/ |  / |__  |__/ | |__/  __/  \_/     //
//                               |           /      //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract PM is ERC721Creator {
    constructor() ERC721Creator("procedural motion", "PM") {}
}
