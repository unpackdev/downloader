// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Immersive - The AI Art Installation
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//                   ___  __   __          ___                      //
//    |  |\/|  |\/| |__  |__) /__` | \  / |__                       //
//    |  |  |  |  | |___ |  \ .__/ |  \/  |___                      //
//                                                                  //
//     __                                                           //
//    |__) \ /                                                      //
//    |__)  |                                                       //
//                                                                  //
//     __   __   __         ___  __                                 //
//    / _` /  \ |  \ |  | |  |  /__`                                //
//    \__> \__/ |__/ |/\| |  |  .__/                                //
//                                                                  //
//                                                                  //
//                                                                  //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract IMAI is ERC721Creator {
    constructor() ERC721Creator("Immersive - The AI Art Installation", "IMAI") {}
}
