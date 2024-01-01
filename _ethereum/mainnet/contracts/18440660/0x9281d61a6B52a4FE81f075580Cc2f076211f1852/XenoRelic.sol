// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Xenorelics
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//    ________                 ___                              ___       ___       ___                                          _                          //
//    `MMMMMMMb.  68b          `MM                              `MM       `MMb     dMM'                                         dM.                         //
//     MM    `Mb  Y89           MM                               MM        MMM.   ,PMM                                         ,MMb               /         //
//     MM     MM  ___   ____    MM  __      ___    ___  __   ____MM        M`Mb   d'MM    ___      ____      ___               d'YM.    ___  __  /M         //
//     MM     MM  `MM  6MMMMb.  MM 6MMb   6MMMMb   `MM 6MM  6MMMMMM        M YM. ,P MM  6MMMMb    6MMMMb\  6MMMMb             ,P `Mb    `MM 6MM /MMMMM      //
//     MM    .M9   MM 6M'   Mb  MMM9 `Mb 8M'  `Mb   MM69 " 6M'  `MM        M `Mb d' MM 8M'  `Mb  MM'    ` 8M'  `Mb            d'  YM.    MM69 "  MM         //
//     MMMMMMM9'   MM MM    `'  MM'   MM     ,oMM   MM'    MM    MM        M  YM.P  MM     ,oMM  YM.          ,oMM           ,P   `Mb    MM'     MM         //
//     MM  \M\     MM MM        MM    MM ,6MM9'MM   MM     MM    MM        M  `Mb'  MM ,6MM9'MM   YMMMMb  ,6MM9'MM           d'    YM.   MM      MM         //
//     MM   \M\    MM MM        MM    MM MM'   MM   MM     MM    MM        M   YP   MM MM'   MM       `Mb MM'   MM          ,MMMMMMMMb   MM      MM         //
//     MM    \M\   MM YM.   d9  MM    MM MM.  ,MM   MM     YM.  ,MM        M   `'   MM MM.  ,MM  L    ,MM MM.  ,MM          d'      YM.  MM      YM.  ,     //
//    _MM_    \M\__MM_ YMMMM9  _MM_  _MM_`YMMM9'Yb._MM_     YMMMMMM_      _M_      _MM_`YMMM9'Yb.MYMMMM9  `YMMM9'Yb.      _dM_     _dMM__MM_      YMMM9     //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract XenoRelic is ERC1155Creator {
    constructor() ERC1155Creator("Xenorelics", "XenoRelic") {}
}
