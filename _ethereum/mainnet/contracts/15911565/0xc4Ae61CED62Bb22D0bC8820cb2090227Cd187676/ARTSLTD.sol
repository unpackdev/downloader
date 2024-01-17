
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ART OF SOLITUDE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//           _     ________   __________   ____   ________  ____      ____   ____     ______________ ____     __________  __________     //
//          dM.    `MMMMMMMb. MMMMMMMMMM  6MMMMb  `MMMMMMM 6MMMMb\   6MMMMb  `MM'     `MM'MMMMMMMMMM `MM'     `M`MMMMMMMb.`MMMMMMMMM     //
//         ,MMb     MM    `Mb /   MM   \ 8P    Y8  MM    \6M'    `  8P    Y8  MM       MM /   MM   \  MM       M MM    `Mb MM      \     //
//         d'YM.    MM     MM     MM    6M      Mb MM     MM       6M      Mb MM       MM     MM      MM       M MM     MM MM            //
//        ,P `Mb    MM     MM     MM    MM      MM MM   , YM.      MM      MM MM       MM     MM      MM       M MM     MM MM    ,       //
//        d'  YM.   MM    .M9     MM    MM      MM MMMMMM  YMMMMb  MM      MM MM       MM     MM      MM       M MM     MM MMMMMMM       //
//       ,P   `Mb   MMMMMMM9'     MM    MM      MM MM   `      `Mb MM      MM MM       MM     MM      MM       M MM     MM MM    `       //
//       d'    YM.  MM  \M\       MM    MM      MM MM           MM MM      MM MM       MM     MM      MM       M MM     MM MM            //
//      ,MMMMMMMMb  MM   \M\      MM    YM      M9 MM           MM YM      M9 MM       MM     MM      YM       M MM     MM MM            //
//      d'      YM. MM    \M\     MM     8b    d8  MM     L    ,M9  8b    d8  MM    /  MM     MM       8b     d8 MM    .M9 MM      /     //
//    _dM_     _dMM_MM_    \M\_  _MM_     YMMMM9  _MM_    MYMMMM9    YMMMM9  _MMMMMMM _MM_   _MM_       YMMMMM9 _MMMMMMM9'_MMMMMMMMM     //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//           _     ________   __________   ____   ________  ____      ____   ____     ______________ ____     __________  __________     //
//          dM.    `MMMMMMMb. MMMMMMMMMM  6MMMMb  `MMMMMMM 6MMMMb\   6MMMMb  `MM'     `MM'MMMMMMMMMM `MM'     `M`MMMMMMMb.`MMMMMMMMM     //
//         ,MMb     MM    `Mb /   MM   \ 8P    Y8  MM    \6M'    `  8P    Y8  MM       MM /   MM   \  MM       M MM    `Mb MM      \     //
//         d'YM.    MM     MM     MM    6M      Mb MM     MM       6M      Mb MM       MM     MM      MM       M MM     MM MM            //
//        ,P `Mb    MM     MM     MM    MM      MM MM   , YM.      MM      MM MM       MM     MM      MM       M MM     MM MM    ,       //
//        d'  YM.   MM    .M9     MM    MM      MM MMMMMM  YMMMMb  MM      MM MM       MM     MM      MM       M MM     MM MMMMMMM       //
//       ,P   `Mb   MMMMMMM9'     MM    MM      MM MM   `      `Mb MM      MM MM       MM     MM      MM       M MM     MM MM    `       //
//       d'    YM.  MM  \M\       MM    MM      MM MM           MM MM      MM MM       MM     MM      MM       M MM     MM MM            //
//      ,MMMMMMMMb  MM   \M\      MM    YM      M9 MM           MM YM      M9 MM       MM     MM      YM       M MM     MM MM            //
//      d'      YM. MM    \M\     MM     8b    d8  MM     L    ,M9  8b    d8  MM    /  MM     MM       8b     d8 MM    .M9 MM      /     //
//    _dM_     _dMM_MM_    \M\_  _MM_     YMMMM9  _MM_    MYMMMM9    YMMMM9  _MMMMMMM _MM_   _MM_       YMMMMM9 _MMMMMMM9'_MMMMMMMMM     //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//           _     ________   __________   ____   ________  ____      ____   ____     ______________ ____     __________  __________     //
//          dM.    `MMMMMMMb. MMMMMMMMMM  6MMMMb  `MMMMMMM 6MMMMb\   6MMMMb  `MM'     `MM'MMMMMMMMMM `MM'     `M`MMMMMMMb.`MMMMMMMMM     //
//         ,MMb     MM    `Mb /   MM   \ 8P    Y8  MM    \6M'    `  8P    Y8  MM       MM /   MM   \  MM       M MM    `Mb MM      \     //
//         d'YM.    MM     MM     MM    6M      Mb MM     MM       6M      Mb MM       MM     MM      MM       M MM     MM MM            //
//        ,P `Mb    MM     MM     MM    MM      MM MM   , YM.      MM      MM MM       MM     MM      MM       M MM     MM MM    ,       //
//        d'  YM.   MM    .M9     MM    MM      MM MMMMMM  YMMMMb  MM      MM MM       MM     MM      MM       M MM     MM MMMMMMM       //
//       ,P   `Mb   MMMMMMM9'     MM    MM      MM MM   `      `Mb MM      MM MM       MM     MM      MM       M MM     MM MM    `       //
//       d'    YM.  MM  \M\       MM    MM      MM MM           MM MM      MM MM       MM     MM      MM       M MM     MM MM            //
//      ,MMMMMMMMb  MM   \M\      MM    YM      M9 MM           MM YM      M9 MM       MM     MM      YM       M MM     MM MM            //
//      d'      YM. MM    \M\     MM     8b    d8  MM     L    ,M9  8b    d8  MM    /  MM     MM       8b     d8 MM    .M9 MM      /     //
//    _dM_     _dMM_MM_    \M\_  _MM_     YMMMM9  _MM_    MYMMMM9    YMMMM9  _MMMMMMM _MM_   _MM_       YMMMMM9 _MMMMMMM9'_MMMMMMMMM     //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ARTSLTD is ERC721Creator {
    constructor() ERC721Creator("ART OF SOLITUDE", "ARTSLTD") {}
}
