// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Free Potatoes
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

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


contract FP is ERC1155Creator {
    constructor() ERC1155Creator("Free Potatoes", "FP") {}
}
