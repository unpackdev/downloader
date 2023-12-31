// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Geometric
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
//      .g8"""bgd `7MM"""YMM    .g8""8q. `7MMM.     ,MMF'`7MM"""YMM MMP""MM""YMM `7MM"""Mq.  `7MMF' .g8"""bgd     //
//    .dP'     `M   MM    `7  .dP'    `YM. MMMb    dPMM    MM    `7 P'   MM   `7   MM   `MM.   MM .dP'     `M     //
//    dM'       `   MM   d    dM'      `MM M YM   ,M MM    MM   d        MM        MM   ,M9    MM dM'       `     //
//    MM            MMmmMM    MM        MM M  Mb  M' MM    MMmmMM        MM        MMmmdM9     MM MM              //
//    MM.    `7MMF' MM   Y  , MM.      ,MP M  YM.P'  MM    MM   Y  ,     MM        MM  YM.     MM MM.             //
//    `Mb.     MM   MM     ,M `Mb.    ,dP' M  `YM'   MM    MM     ,M     MM        MM   `Mb.   MM `Mb.     ,'     //
//      `"bmmmdPY .JMMmmmmMMM   `"bmmd"' .JML. `'  .JMML..JMMmmmmMMM   .JMML.    .JMML. .JMM..JMML. `"bmmmd'      //
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GEOMETRIC is ERC721Creator {
    constructor() ERC721Creator("Geometric", "GEOMETRIC") {}
}
