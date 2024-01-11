
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VoxelNFTs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
//    ____     ___                          ___ ___      ___________ __________                                           //
//    `Mb(     )d'                          `MM `MM\     `M'`MMMMMMM MMMMMMMMMM                                           //
//     YM.     ,P                            MM  MMM\     M  MM    \ /   MM   \                                           //
//     `Mb     d'  _____  ____   ___  ____   MM  M\MM\    M  MM          MM   ____                                        //
//      YM.   ,P  6MMMMMb `MM(   )P' 6MMMMb  MM  M \MM\   M  MM   ,      MM  6MMMMb\                                      //
//      `Mb   d' 6M'   `Mb `MM` ,P  6M'  `Mb MM  M  \MM\  M  MMMMMM      MM MM'    `                                      //
//       YM. ,P  MM     MM  `MM,P   MM    MM MM  M   \MM\ M  MM   `      MM YM.                                           //
//       `Mb d'  MM     MM   `MM.   MMMMMMMM MM  M    \MM\M  MM          MM  YMMMMb                                       //
//        YM,P   MM     MM   d`MM.  MM       MM  M     \MMM  MM          MM      `Mb                                      //
//        `MM'   YM.   ,M9  d' `MM. YM    d9 MM  M      \MM  MM          MM L    ,MM                                      //
//         YP     YMMMMM9 _d_  _)MM_ YMMMM9 _MM__M_      \M _MM_        _MM_MYMMMM9                                       //
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract V721 is ERC721Creator {
    constructor() ERC721Creator("VoxelNFTs", "V721") {}
}
