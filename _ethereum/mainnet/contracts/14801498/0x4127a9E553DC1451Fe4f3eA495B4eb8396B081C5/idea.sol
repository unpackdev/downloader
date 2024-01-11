
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IDEARTIST
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                           //
//                                                                                           //
//                                                                                           //
//                                                                                           //
//                                                                                           //
//    ____________  __________        _     ________   __________ ____  ____  __________     //
//    `MM'`MMMMMMMb.`MMMMMMMMM       dM.    `MMMMMMMb. MMMMMMMMMM `MM' 6MMMMb\MMMMMMMMMM     //
//     MM  MM    `Mb MM      \      ,MMb     MM    `Mb /   MM   \  MM 6M'    `/   MM   \     //
//     MM  MM     MM MM             d'YM.    MM     MM     MM      MM MM          MM         //
//     MM  MM     MM MM    ,       ,P `Mb    MM     MM     MM      MM YM.         MM         //
//     MM  MM     MM MMMMMMM       d'  YM.   MM    .M9     MM      MM  YMMMMb     MM         //
//     MM  MM     MM MM    `      ,P   `Mb   MMMMMMM9'     MM      MM      `Mb    MM         //
//     MM  MM     MM MM           d'    YM.  MM  \M\       MM      MM       MM    MM         //
//     MM  MM     MM MM          ,MMMMMMMMb  MM   \M\      MM      MM       MM    MM         //
//     MM  MM    .M9 MM      /   d'      YM. MM    \M\     MM      MM L    ,M9    MM         //
//    _MM__MMMMMMM9'_MMMMMMMMM _dM_     _dMM_MM_    \M\_  _MM_    _MM_MYMMMM9    _MM_        //
//                                                                                           //
//                                                                                           //
//                                                                                           //
//                                                                                           //
//                                                                                           //
//                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////


contract idea is ERC721Creator {
    constructor() ERC721Creator("IDEARTIST", "idea") {}
}
