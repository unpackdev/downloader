
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Perfect World
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//    ________        ____      _  ____     ___     //
//    `MMMMMMMb.      `MM'     dM. `MM(     )M'     //
//     MM    `Mb       MM     ,MMb  `MM.    d'      //
//     MM     MM       MM     d'YM.  `MM.  d'       //
//     MM     MM       MM    ,P `Mb   `MM d'        //
//     MM     MM       MM    d'  YM.   `MM'         //
//     MM     MM       MM   ,P   `Mb    MM          //
//     MM     MM       MM   d'    YM.   MM          //
//     MM     MM (8)   MM  ,MMMMMMMMb   MM          //
//     MM    .M9 ((   ,M9  d'      YM.  MM          //
//    _MMMMMMM9'  YMMMM9 _dM_     _dMM__MM_         //
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract NEXTLIFE is ERC721Creator {
    constructor() ERC721Creator("A Perfect World", "NEXTLIFE") {}
}
