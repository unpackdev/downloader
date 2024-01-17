
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: X SOLDIERS ART
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMx                     ,MMMMMMMMMMMMMMMMMMMMMMMMMM#^                  .MMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMk.                     TMMMMMMMMMMMMMMMMMMMMMMM$                  .dMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMN,                     JMMMMMMMMMMMMMMMMMMMMM'                  .MMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMe                     .HMMMMMMMMMMMMMMMMMD        .gggggggggggMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMh.                     TMMMMMMMMMMMMMMM3        (M""""""""YMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMN,                     (MMMMMMMMMMMM#!       .MD        .MMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMp                      WMMMMMMMMMF        .M3        (MMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMN.                     7MMMMMMM^        J#!       .MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMM,                     ,MMMM#`       .MF        .MMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMb                     .MMD        .M^        JMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN,                  (MM^       .d#`       .MMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM,               .MM@        .MD        .MMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMm             .MM"        .M^       .dMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN,          JMM'       .d@        .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMe       .MMD        .M"        .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMh.   `.MMNggggggggkM'       .dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN  .dM#"""""""""""        .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM#` .MMF                   (MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMD  .MM=                  .MDTMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM^ .dM#`                  .Mt  ,MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM@  .MMD                   J#!     WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMD  (MM^                  .MF        ?MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM' .MM@`                  .M=          ,MMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMD  .MMD                  .d#`             UMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMt  JMM^                  .MD                ?MMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMM#! .MM@                   .M^                  .MMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMF  .MM$                  .dN.                     TMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMM= .gM#!                  .MMMN,                     (MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMM#` .MMF                   (MMMMMMp                     .HMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMD  .MM=                  .MMMMMMMMMN.                     TMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMM^ .dM#`                  .MMMMMMMMMMMN,                     ,MMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMM@` .MMF                   JMMMMMMMMMMMMMMp                      WMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMD  .MM^                  .MMMMMMMMMMMMMMMMMN.                     ?MMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMM^ .MMB`                  .MMMMMMMMMMMMMMMMMMMM,                     ,MMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMM@  .MMD                  .JMMMMMMMMMMMMMMMMMMMMMMm                      UMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNNNMMMNNNNNNNNNNNNNNNNNNNNMMMMMMMMMMMMMMMMMMMMMMMMMNNNNNNNNNNNNNNNNNNNNNNNMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMH"""""""WMM"""""""MMMMM#""WMMMMM#"""HMMMMMMM""""HMMH"""""""WMMH""""""HMMMM#""""""WMMMM    //
//    MMMMMMMMMMMMM^  ......MF  .....  .MMD  .MMMMM=  .  ?MMMMM#   .MM'  ......MM^  ....   dMD  .......MMM    //
//    MMMMMMMMMMM@   (MMMMMM=  .MMM3  .MM^  .MMMM#`  .Mp  ,MMMD   JMD   JMMMMMM@   (MM@   (M^  .MMMMMMMMMM    //
//    MMMMMMMMMMN.  ?777WM#`  .MM#`  .M@   JMMMMD  .dMMD  .dMt  .MMt   ?771MMM"   ?77^  .MM,  .777TMMMMMMM    //
//    MMMMMMMMMMMMN#'  .MF  .dMMF  .dM$  .MMMMM^  .MMM^  .M#!  .M#!  .NNNNMMM'  .N\  .gNMMMMMN%  .dMMMMMMM    //
//    MMMMMMMMMMMMB`  .M^  .MMM^  .MH'  .MMMM@   (MM@`  -MF  .dMF  .dMMMMMMD   JM'  .MMMMMMMM^  .MMMMMMMMM    //
//    MMMD          .MM]          MM[     .dD         .MM3  .MM3        .Mt  .MM]  .MF         .MMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract XSA is ERC721Creator {
    constructor() ERC721Creator("X SOLDIERS ART", "XSA") {}
}
