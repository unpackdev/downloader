// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: YUO.+MATE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                     ......                                                                     .......                                         //
//                ..gMMMMMMMMNNJ, ...JJ..                                    .....  .MMMMMMMMMN,.            ..(gNNNNNag.,       ....                         ..MMMMMMMMMMm,                                      //
//             .gMMMMMMMMMMMMMMMMMM#""HMMN,        .......    .MMMMMa,    .dMMMMMMN&M#"!` _7"MMMMN,       .gMMMMMMMMMMMMMMMNa,.dMMMMMMNJ.    ..gMMMMMMMMNg,  -MM"^     .7WMMN,.&NNg,      ...Jggggg-..            //
//           .MMMM#"!         .7HMMM,   (MMb   .gMMMMMMMMMMNaM@! _TMMMp  .MMM#""YMMMN,        .TMMMN,   .MMM#"`         -"WMMMM@^   .7HMMm..dMMM"""777"TWMMMMB!     .      TMMMMHMMMN. .gMMMMMMMMMMMMMMN,         //
//         .MMM#^                .UMMp    MM[.MMB"!     -7TMMMMa.   /MMc dM#`     ?MMN,    ..    TMMMm.JMM"        .g&.     ?MMN,      .TMMMM=      .,    .TMN,    JMN,     ,MM,   TMNMM@=           (TMMN,       //
//        .MM#'                    ?MM,   -MMB'              TMMN,   dM#.MM`       ,MMb    MMN,   .WMMMM@           HMMa      ?MN. .,    ,MMb       WMR     (MN     JMN.     dM]    qMN                 ?MM2      //
//       .MMF                       dM]   ,M#                  7MMb  ,MM-MF         JMM;   ,MMM,    ?MMM,            ?MMh      HM] HMp    .MMb       MM]     MM      MM]    .MM\     MM|                 -MN.     //
//       MMF        .N.             JM]   (MF          MN       ,MMb ,MMgM{          MMb     MMM,    -MMN,            dMM]     JMF .MMc     MM[      JMD   .JM#       7  ..dMMF      dMb                  MM}     //
//      .MM`        .M]            .MM`   MM\          WMb       ,MM,.MMMM_          MM#     -MMN     JMMb            .MM%    .MM%  dMN     ,MN.      ...JMMMM^       .MMMMMMD       JMN          `      .MM!     //
//      dMF          ?Ma.   `  `..MMM^   .M#           .MM<       MM]dMMMMMN,        MM#     ,MMM      MMM<    `             .MM#   ,MF      dMb     ,MMMMMMM:        -MMMMMN        (MM    `  `  MNJ...JMMF      //
//      MM]          dMMMMNaggMMMMM@`   .MMb            dM]       JMNMMH"MMMM#      .MMF      WMF      JMM]               ..dMMB`            .MN      T"MMMMMb      (a .TMMMN.       .MM` .MN.    MMMMMMMMF       //
//      MM]          MMMMMMMMMMMM=      -MMMMMMMMNg,    dM]       dMMMF    ?"3      -MMt               JMM]     ..(J+gggMMMMM#=               MM|         .TMMb     dMb   TMMN       -MM(+MMM>    dMHMMH"`        //
//      MMb      `  .MM#"!~?THMMMN,     (MMMMMMMMMMMN,  W#`    ` .MM%            ` .MM#                MMM\     (WMMMMMMM""^    .gg.....   `  dM]   .MN.    ?MM|    -MM    4MM[      (MMMMMMF     ,MN             //
//      (MN.         .'        TMMM,              TMMM,          dM#              .MMMF    `      `   JMM#   `        ?MM,      (MMMMMM]      dM]    MMb     MMF    (MM`   .MMF  `   (MMMMMM`      MM]            //
//      .MMb  `                 .MMN.  `  `         MMF      ` .dMM'             .MMMM]       `     .dMMM'      .,     4MN.     .MMY4MMN.    .MM\    JMM    .MMNJ.   7'   .MMM]      (MM MMF       JM#            //
//       (MMp                    .MM]              .MMF       .MMMMm,         ..MMMMMMN           .dMMMM]      .MN      MMN,    .MM$MMMMN,..(MM@     dM#    JMMMMMN,.   .JMMMM       dM# MM]       -MM            //
//        TMMm                   .MMm.....   .....MMMM-....JMMMMMMMMMMMNggggMMMMMMD(MMMNJ......(NMMMMM#MN.     .MM[     -MMMMaggMMM!.""TMMMMMMMN,         .MMM#WMMMMMMMMMMMMMM.     .MM] MMb       JMM            //
//         ?MMNJ                 JMMMMMMMMMMMMMMMMMMMMMMMMMMMM@'.MMMMMMMMMMMMMMM"   UMMMMMMMMMMMMMMMM: 4Mh.   .MMMMe.  .dMMMMMMMMM^      ""UMMMMMMNg+J+gMMMMM@  .TMMMMMMMMM^MMN,...dMM#  dMMm,....MMMF            //
//          ,MMMMm,            .MMMM@"HMMMMMMMM#""`MMWMMMMBM#    MMMN"TMMMMMMMMF     (HMMMMMMMMMMHMMM]  UMMNgMMM#(MMMMMMMMF ?"""'          JMMMHMMMMMMMMMMM@!        _!` MN.,MMMMMMMMM]   TMMMMMMMMMD             //
//            ?MMMMMNaJ......+MMM#(MF        .M]   MM.  dM.MN    dMMM| UMMMMMM#`         ?777!   .MMMN   (WMMMMMF  7WMMMB^         .NNNNNNNMMNF  JMM"MMY7`               MM\ .TMMMM@jM]    .TMMMMMN               //
//              MMMMMMMMMMMMMMMM@ .MF        ,M]  .MM{  MM/M#    .MNMN  .T"""^                    MMNM.     .MMMF.MMM2             MMMMMMMMNMM'  JM# MM]                  `    MF.M].M]      MM].MM,              //
//             .MM.  M#"""""^  MN (MF        .M@   ?"   MM|       dMMM[           ..gNg..         JMMMMMMMMMMMNML,MMM@               ````JMMMF   dM# WM^                       Mb.M].M\      MMb,MM]              //
//              MM~ .MN        MM            ,M#        MM]       .MMMN.         (MMMMMMM,     .(MMMNMMNMMMMMNMMMMMMNF                  .MMN@    JM#                          .M#,MF         MMN.MMt              //
//              ?"  .MM.       MM`           -MM        MMF        -MMMb        .MMMMMMMM#   .JMMMMM"=`      _THMNMMM]           .......MMMM`     "`                          .M#,MF         MMM_                 //
//                  .MM{                     ,MM        TMF         4MMMb        UMMMMMMM%  .MMMM@!        ..+, -MMNMMb         MMMMMMMMMNMt                                  .MN            dMM:                 //
//                  .MM]                      _!                     WMMMp        .TMMM9`  .MMMM^          dMMMMMMMMMMMb        ?HMMMMMMMMF                                   .MM             "^                  //
//                  -MM]                                              HMMM2             ..MMMMM!           .MMMMNMD 4MMM]            .MMNM`                                   .MM.                                //
//                  JMMF                            ..gN,             .MMMMx          .JMMMMNMF              TMMMMb .MNMNNMMMMNNg,.  dMMM\                                    .MM`                                //
//                  JMM#                       ..gMMMMMM#              .MMMMe        .MMMMWMMM)                T"9!  MMMMMMMMMMMMMMMNMMMF                                      MM                                 //
//                   79!                    .MMMMMMMMMMM#               .MMMM[      .MMMF JMMN]                     .MMN#       ?YMMMMN#                                                                          //
//                                          WMMMY4MMMMMM#                 HMMMp    .MMMF  .NMMN.                    (MNMF          .TMMMN,                 ..(gMMMMMMMMNNa,.                                      //
//                                   .MN,       .MMMMMMM#                  WMMMb   MMMF    ?MMMN,                  -MMM@             .UMMMp             .gMMMMMMMMMMMMMMMMMMMm,                                   //
//                                 .dMMMMp     .MMMM^MMM#        ..JgMMMMMMMNMMMb .MMM\     ?MMMMa.              .MMMM@                ?MMMb         .+MMMMMMH"""7???7""HMMMMMMNJJMMMMNJ,                         //
//                                .MMMMMMMh   .MMM#` MMMF     .(MMMMMMMMMMMMMNMMMMMMNM`      .WMNMMNJ,     ` ..gMMMMM3                  ?MMM|      .dMMMM9^                ?YMMMMMY"TWMMMN,                       //
//                               .MMMM^?MMMN.MMMMF   ."^    .dMMMM@=`        _"YMMMNMM         .YMMMMMMMMMMMMMMMMM#=                     MMM#     .MMMB^                      TMMMN,   (MMMp                      //
//                              .MMMM!  (MMMMMMM^          JMMM#^                 7WMD            _THMMMMMMMMMM"^                        JMNM.  .dMM#'                         .MMMN     WMM,    ...(&gg+-..      //
//          .....,             .MMMH`    .MMMM@`         .MMMM^                                                                          (MMMN,.MMMD                             MMM]    .MM] .gMMMMMMMMMMMMMN    //
//        .MMMMMMMMm, .JMMMMNa.MMM#`       7"=          .MMM#`                                               ..   ..         .J,         dMMNMMMMMt           .,                 ,MMF     MMNMMH""!`   `?""MMM    //
//      .MMMMY"""HMMMMMMH"WMMMMMMM`                     JMNM`                   ..,       .gMN. .MMN,      .MMM] JMMMx     .MMMM\       .MMMMMMMMF            M#                 .MMF    .MMM=               ?    //
//     .MMM^  ..,  TMMb   .. 7MMM[                     .MMMt                   JMMMm,    .MMMM^ ,MMMMh,  .dMMM#! ,HMMMN,  .MMMM3       .MMM@-MNM#             MN.                -MM'    (MM`                     //
//     dMM`  dMMMN. (MM| MMMM, MMN.                    (MMM                     TMNMMa..JMMM#!    TMMMMa.MMMMD     ?MMMMNMMMM@`       .MMM@  MMMN             dMh.              .MMF    .MMF                      //
//    .MMF   MMMMMb  HMN MMMMN ,MM]                    dMN#                      .WMMMMMMMMF       .WNMMMMM#'        TMMMMMM3       .dMMM#.. dMMM_           .MMMMa,         .JMMMF    .MM#             .N,       //
//    .MM]   ,MMMMM. -MM .MMMM~.MM]                    JMMN                        ,HNMMMM^          (MNMMN,         .MMMNMN,      jMMMNMMMMMMMNM.           MMMMMMMMMNggNMMMMMM#^    .MMM!             MMN       //
//     MMb   .MMMMM! ,MM(MMMM# dMM\                    ,MMMc                       .MMMNMMN,       .MMMNMNMMm.     .JMMNMMMMMN,    ?MM"""""WMMMMMMN,        -MMMMMMMMMMMMMMMMM"!      dMM^           ...dMMa..    //
//     dMM,  ,MMMM#  -M# TMMM!(MM@                      WMMN.                     (MMMMTMMMMm.    (MMMM% UMMMN,   .MMMMF  7MMMMa               7HMMMN,      dMMB"??7"MMMMMM,         dMMM,.        .MMMMMMMMMM    //
//     ,MMM,  WMMM3 .MMh,  ..MMMM`                      JMMMN,              `   .MMMMD   TMMMMp .MMMN@`   ,MMMMb (MMM#'    .WMMM]                .TMMMh.     `        .WMMMMe       -MMMMMMMMNg,.   ?7774MMYHM    //
//      ?MMMN.....(MMMMMMMMMMMM#-   ...JJ.,             (MNMMMN,.        `     .MMMM^     .WMMF .WM#^       7HB'  T"=        .7'                   ,MMMN.               ,MMMM,      JMMMMMMMMMMMMN,     dMM       //
//       -MMMMMMMMMMMMMMMMMMMMMMMMaMMMMMMMMMN,          ,MMNMMMMMNgJ.......,    ."=                                                                 ,MMMb                .MMM@            _?TWMMMMMb   .MMF       //
//         JMMMMMMMMM""""""""WMMMMMMN,   .TMMMb     ..MMMMMMM/TWMMMMMMMMMMMM[                         .......                                        -MMM|       ...(JJ...-MMM                 (HMMM]  ,""        //
//       .dMMMMM"^              _TMMMMb     ?MMb  .MMMMM""MNMN.   _7""UMMNM3                       .dMMMMMMMMMm,                                      MMMb   ..MMMMMMMMMMMMMMM                   UMMN.JggNNNNa    //
//      .MMMM"`                    ?MMMb     ?MMaMM#"`    ?MNMN,     .MMN@`                        JMMM#"""MMMM#                                      dMNN .dMMMM#"""""T"MMMMMN, .gMMMMN,      ..dMMMMMMMMMMMM    //
//    .dMMM"                        .HMM]     MMM#'        JMNMMx   .MMNF                            `       ?7                                       dMMNJMM#"            (TMMMNMMMMMMMMN,  .MMMMM#""!`          //
//    MMMB`                           MMN     MM#           .MMMMN, dMM#                                                                              MMMMM#!                 TMMMF    TMMMaMMM#=                 //
//    MMF                             JMM     MMF            .MMMMMMMMN]                                                                             .MMMMMMb      MMm,        ,MMN      WMMM"                    //
//    M#           M]                 dM#    .MMF            (MM#WMMNMM{                                                   `    `                   .MMMFTMMMb     ,MMMp        dMM-      HMM[                    //
//    M'           MN                .MMF    -MM:             4MM[ ?MMM)                                               `   JMNg,.                 .JMMNF  4MMMb      WMM]       dMM}      ,MMN.                   //
//    F            -MN.            .MMM@     MM#               MMN  MMMb                                            `      MMMMMMMNJ..         ..MMMMM=    WMMM,     ,MM#      (MMM`       dMMb                   //
//    ]             dMMm,.    ...gMMMMF     -MMb               JMM. (MNM,            `     `   `                           dMNMWMMMMMMMMMMMMMMMMMMM#=      .MNMN      ,"'   ..MMMMF        ,MMN.                  //
//    [            .MMMMMMMMMMMMMMMM@!      MMMMggggggJ..      (MM~  MMMM,        `            (MMb  `           `         dMM#   _TMMMMMMMMMMMH"^          JMMM[       .(gMMMMMMD          MMM[            .M    //
//    ]            .MMMMMMMMMMMMMMr        .MMMMMMMMMMMMMMa.   dM#  .MMNMMm.                 .MMMMM,       `              .MMMF     ?MMN  WMMM[              MMMN       MMMMMMMMb           dMMb             M    //
//    ]            JMMMM9""""MMMMMMh.       WMMMH""HMMMMMMMM,  ."'  .MMMMMMMm,            .+MMMMMMMN,                     (MMM'      vMMb  MMNN              dMMM.      UMMMMMMM#           JMM#   .MMp      d    //
//    N            .MM^        ?HMMMN,                  ?MMMM,      .MNMF?MMMMMNa......JMMMMMMD` MMMN,                   .MMMF        WMMc (MMM]             (MMM}   .-,  TMMMMMM,          -MMM  .MMMM`     .    //
//    Mp.&NMMMMMMMNNg.,          ,MMMM,                   4MMb       MMN@  .TMMMMMMMMMMMMMM"^     UMMMN,      `       `.MMMM#^        .MMN .MNMN             -MNM)   dMN,   .WMMMM,         ,MMM+MMMMMF   ..Jg    //
//    MMMMMMMMMMMMMMMMMMMg,      ..MMMb.                  .MM#       MMMN       ?""""YMMM]         (MMMMNa,.        .(MMMM#'        ..gMMMMMMMMM.            (MMM:    MMN.    JMMMN.     ..NMMMMMMMMMM\ .+MMMM    //
//    MM""7`     ?7TWMMMMMMMm,.JMMMMMMMMMa,            ...MMMh.     .dMNM.            MMNN,          (YMMMMMMMNNNMMMMMMMB^      .(MMMMMMMMMMMMNMb            MMMM     MMMb..JgNMMMMh..  .MMMMMMMMMMMM# .MMMMMM    //
//                     _TMMMMMMMH""77""MMMMN,`  ...(MMMMMMMMMMMMMNMMMMMMN]            ,MMMN,         ...(MMMMMMMMMMM#"'       .MMMMMMM#9"7!``WMMM,          .MNMMh    MMMMMMMMMMMMMMMMMMM%     ?HMMMMF dMM#^      //
//              .N,       .TMMMN,        TMMMMMMMMMMMMMH"""""HMMMMMMMMMMMN             (MMMMN,  jMMMMMMMMMMMMM#"`     .Ngg+&gMMMMMB^         .MMMM,        .MMM#MMb .dMMMY"=`     ?"YMMMMMN,     ?MMM].MM#        //
//              MMMN,        WMMN.         TMMMMMMB^             (TMMMMNMM,             4MNMMM+MMMMMMMMWMMMN   ....(JJMMMMMMMMM#^             .MMMMN,   ..MMMMD JMMgMM"`               ?HMMMN,    MMM]JMM'        //
//               UMMMp        4MMb  ...     ,MMM#`         .N,      (MMMMMb              MMMMMMM"""MMMMp(MMMNMMMMMMMMMMMMMMMMMe.                7MMMMMMMMMMMM^   MMM"                    .TMMMx   -MMNdM#         //
//                UMMMp        MMN  dMN.      MMMb         XMMb       UMMNMc             (MNMMMb    .WMMbJMMMM#""7?!!??7""HMMMMMNJ                ?"MMMMMMM#     MMF             .         ,MMMp  .MMMMM]         //
//                 MMMM.       MMM` ,MMb       MMM|         MMM[      .MMMMM,            -MMMMM#      MMMMB^                 ?YMMMN,                     dMN     MMF            .MN.         HMM[ .MMMMM]         //
//                 dMMM`      .MMM   MMM[      ,MMN.        -MMF      .MMMMMMp           MMMMMMF      ,MMN                      TMMMp M]                .MM#    .MM%            -MMN         .MMN..MMMMM]         //
//                 ,MMD       JMMF   JMMN       JMMb        .WM^     .MMMFUMMMMa,   `  .MMNMMMM%       MMM-                      ,MMM[MN.              .MMM%    dMM`             JMM]         (MM](MMMMMMMN,.     //
//                          .JMMM`   ,MM#        MMN.           ...JMMMM@  ,WMMMMMMMMMMMMMMMMMF        dMM]                       ,MMN-MN,           .JMMMF    .MMF               MMN         .MM@MMMMMMMMMMM.    //
//                        .(MMMM!     T"^        JMM[       .MMMMMMMMMMD      7YMMMMMMMMMMMMM=         dMMF                        MMM.dMMNg.......gMMMMM=     -MMb               JMM.         MMMMMF   .TMMM`    //
//         ............(gMMMMMD                  ,MMb       -MMMMMMMMMF            dMMMMMMM#           gMMF                       .MMM.MMMMMMMMMMMMMMMM"       MMMMMMMMMMNg..     JMM         .MMMMM'             //
//        MMMMMMMMMMMMMMMMMM"                     MMN        ?"WMMMMMMN.        .. ,MMMMMMM@           dMMF             .J.      .MMMF-MMMMMMMMMMMMMM,        .MMMMMMMMMMMMMMN,   dM#         -MMF                //
//         ?"""HMMMMMMY""!      ..                MMM             ?MMMMN       .MM,  .WMMMMb           MMMF    .,.......MMMa,...(MMMM!JMMMB"!`?7"MMMMMN,       7""""""""TWMMMMMb             .MMM!         .+M    //
//               ,MMMb         .MMMMMMMNx                                                                                                                                                                         //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MATE is ERC721Creator {
    constructor() ERC721Creator("YUO.+MATE", "MATE") {}
}
