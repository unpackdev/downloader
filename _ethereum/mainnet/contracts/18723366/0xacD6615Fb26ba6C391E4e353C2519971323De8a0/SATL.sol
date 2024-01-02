// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Somewhere Along The Line
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//      ____                                                    ___                                             _     ___                                       //
//     6MMMMb\                                                  `MM                                            dM.    `MM                                       //
//    6M'    `                                                   MM                                           ,MMb     MM                                       //
//    MM         _____  ___  __    __     ____  ____    _    ___ MM  __     ____  ___  __   ____              d'YM.    MM   _____  ___  __     __               //
//    YM.       6MMMMMb `MM 6MMb  6MMb   6MMMMb `MM(   ,M.   )M' MM 6MMb   6MMMMb `MM 6MM  6MMMMb            ,P `Mb    MM  6MMMMMb `MM 6MMb   6MMbMMM           //
//     YMMMMb  6M'   `Mb MM69 `MM69 `Mb 6M'  `Mb `Mb   dMb   d'  MMM9 `Mb 6M'  `Mb MM69 " 6M'  `Mb           d'  YM.   MM 6M'   `Mb MMM9 `Mb 6M'`Mb             //
//         `Mb MM     MM MM'   MM'   MM MM    MM  YM. ,PYM. ,P   MM'   MM MM    MM MM'    MM    MM          ,P   `Mb   MM MM     MM MM'   MM MM  MM             //
//          MM MM     MM MM    MM    MM MMMMMMMM  `Mb d'`Mb d'   MM    MM MMMMMMMM MM     MMMMMMMM          d'    YM.  MM MM     MM MM    MM YM.,M9             //
//          MM MM     MM MM    MM    MM MM         YM,P  YM,P    MM    MM MM       MM     MM               ,MMMMMMMMb  MM MM     MM MM    MM  YMM9              //
//    L    ,M9 YM.   ,M9 MM    MM    MM YM    d9   `MM'  `MM'    MM    MM YM    d9 MM     YM    d9         d'      YM. MM YM.   ,M9 MM    MM (M                 //
//    MYMMMM9   YMMMMM9 _MM_  _MM_  _MM_ YMMMM9     YP    YP    _MM_  _MM_ YMMMM9 _MM_     YMMMM9        _dM_     _dMM_MM_ YMMMMM9 _MM_  _MM_ YMMMMb.           //
//                                                                                                                                           6M    Yb           //
//                                                                                                                                           YM.   d9           //
//                                                                                                                                            YMMMM9            //
//                                                                                                                                                              //
//                                                                                                                                                              //
//    __________ ___                      ____                                                                                                                  //
//    MMMMMMMMMM `MM                      `MM'     68b                                                                                                          //
//    /   MM   \  MM                       MM      Y89                                                                                                          //
//        MM      MM  __     ____          MM      ___ ___  __     ____                                                                                         //
//        MM      MM 6MMb   6MMMMb         MM      `MM `MM 6MMb   6MMMMb                                                                                        //
//        MM      MMM9 `Mb 6M'  `Mb        MM       MM  MMM9 `Mb 6M'  `Mb                                                                                       //
//        MM      MM'   MM MM    MM        MM       MM  MM'   MM MM    MM                                                                                       //
//        MM      MM    MM MMMMMMMM        MM       MM  MM    MM MMMMMMMM                                                                                       //
//        MM      MM    MM MM              MM       MM  MM    MM MM                                                                                             //
//        MM      MM    MM YM    d9        MM    /  MM  MM    MM YM    d9                                                                                       //
//       _MM_    _MM_  _MM_ YMMMM9        _MMMMMMM _MM__MM_  _MM_ YMMMM9                                                                                        //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SATL is ERC721Creator {
    constructor() ERC721Creator("Somewhere Along The Line", "SATL") {}
}
