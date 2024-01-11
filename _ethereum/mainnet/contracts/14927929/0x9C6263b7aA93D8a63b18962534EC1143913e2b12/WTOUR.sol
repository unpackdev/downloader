
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WAGMAM On Tour
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
//                                                                                                //
//                                                                                                //
//                                                                                                //
//    `7MMF'     A     `7MF' db       .g8"""bgd `7MMM.     ,MMF'      db      `7MMM.     ,MMF'    //
//      `MA     ,MA     ,V  ;MM:    .dP'     `M   MMMb    dPMM       ;MM:       MMMb    dPMM      //
//       VM:   ,VVM:   ,V  ,V^MM.   dM'       `   M YM   ,M MM      ,V^MM.      M YM   ,M MM      //
//        MM.  M' MM.  M' ,M  `MM   MM            M  Mb  M' MM     ,M  `MM      M  Mb  M' MM      //
//        `MM A'  `MM A'  AbmmmqMA  MM.    `7MMF' M  YM.P'  MM     AbmmmqMA     M  YM.P'  MM      //
//         :MM;    :MM;  A'     VML `Mb.     MM   M  `YM'   MM    A'     VML    M  `YM'   MM      //
//          VF      VF .AMA.   .AMMA. `"bmmmdPY .JML. `'  .JMML..AMA.   .AMMA..JML. `'  .JMML.    //
//                                                                                                //
//                                                                                                //
//                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////


contract WTOUR is ERC721Creator {
    constructor() ERC721Creator("WAGMAM On Tour", "WTOUR") {}
}
