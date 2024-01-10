
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OXEN
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//                                                        //
//                                                        //
//                                                        //
//      .g8""8q.`YMM'   `MP' `7MM"""YMM  `7MN.   `7MF'    //
//    .dP'    `YM.VMb.  ,P     MM    `7    MMN.    M      //
//    dM'      `MM `MM.M'      MM   d      M YMb   M      //
//    MM        MM   MMb       MMmmMM      M  `MN. M      //
//    MM.      ,MP ,M'`Mb.     MM   Y  ,   M   `MM.M      //
//    `Mb.    ,dP',P   `MM.    MM     ,M   M     YMM      //
//      `"bmmd"'.MM:.  .:MMa..JMMmmmmMMM .JML.    YM      //
//                                                        //
//                                                        //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract OXEN is ERC721Creator {
    constructor() ERC721Creator("OXEN", "OXEN") {}
}
