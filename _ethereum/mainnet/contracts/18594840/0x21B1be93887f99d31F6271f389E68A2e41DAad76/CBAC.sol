// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CryptoBoringApesCreep
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                                                            //
//                                                            //
//       ____   ________        _        ____                 //
//      6MMMMb/ `MMMMMMMb.     dM.      6MMMMb/               //
//     8P    YM  MM    `Mb    ,MMb     8P    YM               //
//    6M      Y  MM     MM    d'YM.   6M      Y               //
//    MM         MM    .M9   ,P `Mb   MM                      //
//    MM         MMMMMMM(    d'  YM.  MM                      //
//    MM         MM    `Mb  ,P   `Mb  MM                      //
//    MM         MM     MM  d'    YM. MM                      //
//    YM      6  MM     MM ,MMMMMMMMb YM      6               //
//     8b    d9  MM    .M9 d'      YM. 8b    d9               //
//      YMMMM9  _MMMMMMM9_dM_     _dMM_ YMMMM9                //
//                                                            //
//                                              Creepc0n ©    //
//                                                            //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract CBAC is ERC721Creator {
    constructor() ERC721Creator("CryptoBoringApesCreep", "CBAC") {}
}
