
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Year Of The Banner
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//    yotb.io provides analytics on the banner (PFB) ecosystem.    //
//                                                                 //
//    2021 = year of the pfp.                                      //
//    2022 = year of the pfb.                                      //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract YOTB is ERC721Creator {
    constructor() ERC721Creator("Year Of The Banner", "YOTB") {}
}
