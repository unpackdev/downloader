// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wall and Piece
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//        `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `    //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//       `                                                                                                                                                                                                `    //
//          `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `        //
//                                                                                                                                                                                                             //
//                                                                                                                               ..JggMM]                                                                `     //
//       `                                                                                                                       dMMMMMM]                                                                      //
//                                                                                                    ....(ggR                   .MMMMMM@                                                                      //
//                                                                                                    -MMMMMM#                    MMMMMMM                                                                      //
//                                                                            ....+gNMMp               MMMMMMM.                   dMMMMMM|                                                                     //
//                                                             `..           `dMMMMMMMMMp              JMMMMMM[                   .MMMMMMF                                                                     //
//                ........................................gWMMMMMt............MMMMMMMMMMMh..............MMMMMMb....................MMMMMMN..............                                                       //
//                MMMMMMMMMMMMMMMMMMMMMMMM""""?UMMMMMMMMM#       MMMMMMMMMMMMt     .      ,MMMMMMMMMMMMM       MMMMMMMMMMMMMMMMMMMM|      MMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMHHMMMMMMMMMM`      HMMMMMMMM#      .MMMMMMMMMMM#      MN.     ,MMMMMMMMMMMM|      dMMMMMMMMMMMMMMMMMMMb      (MMMMMMMMMMMMM                                                       //
//                MMMMN,       MMMMMMMMM#       .MMMMMMMMF      (MMMMMMMMMMMF     .MMN.     .MMMMMMMMMMMF      (MMMMMMMMMMMMMMMMMMMN      .MMMMMMMMMMMMM                                                       //
//                MMMMMN,      ,MMMMMMMMF        .MMMMMMM]      dMMMMMMMMMMM`     (MMMN.      WMMMMMMMMMN      .MMMMMMMMMMMMMMMMMMMM-      MMMMMMMMMMMMM                                                       //
//                MMMMMMN.      ?MMMMMMM]         ,MMMMMM\      MMMMMMMMMMMF      MMMMMN,      UMMMMMMMMM<      MMMMMMMMMMMMMMMMMMMM]      JMMMMMMMMMMMM   ..                                                  //
//                MMMMMMMN.      WMMMMMM!    .     ,MMMMM!     .MMMMMMMMMMM'     .MMMMMMN,      7MMMMMMMM]      JMMMMMMMMMMMMMMMMMMMN      .MMMMM""""7!.MMMMN                                                  //
//                MMMMMMMMh       MMMMM#     (]     -MMMM      (MMMMMMMMMM#      JMM""""7!       ?MMMMMMM#      .MMMMMMMMMMMMMMMMMMMM.                 .MMMMM,                                                 //
//                MMMMMMMMMb      .MMMMF     dM,     JMM#      dMMMMMMMMMM%                       ,MMMMMMM.      MMMMMMMW"""7!    MMM[                 .MMMMM]                                                 //
//                MMMMMMMMMMb      -MMM%     MMN,     ?MF      MMMMMMMMMM#                         ,MMMMMM]      `                (MMF         .....JgNM                                                       //
//                MMMMMMMMMMMp      dMM`    .MMMN,     U]     .MMMMMMMMMMF      .....JggMMMMN,      .MMMMMb                       .MMN..+gNMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMM|      W#     .MMMMN.     t     (MMMMMMMMMM`      MMMMMMMMMMMMMN,       WMMMN           .....JggNMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMM,     .@     JMMMMMN           dMMMMMMMMMF      .MMMMMMMMMMMMMMN,       TMMM....+gNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMM,           MMMMMMMb          MMMMMMMMMM!      dMMMMMMMMMMMMMMMN..(&gNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMN,         .MMMMMMMMb        .MMMMMMMMMF       MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMN.        .MMMMMMMMMb       -MMMMMMMMM+..+gNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMN.       JMMMMMMMMMMc .....dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMb       dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMm&gNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM""""7!           ?TMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW"WMMMMN.                         TMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM[      (MMMMM]              ..           WMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMH"""7!?MMMMMMMMMMMMMN      .MMMMMN      .ggMMMMMMMMMN&.       4MMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN.       .WMMMMMMMMMMMM;      MMMMMM-      MMMMMMMMMMMMMMe       WMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMMMMMM""""7` .MMMMMMMMMMMMMMM]         ,HMMMMMMMMMM]      dMMMMM]      dMMMMMMMMMMMMMMp      .MMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMMMMF         .MMMMMMMMMMMMMMN           (MMMMMMMMMN      -MMMMMN      .MMMMMMMMMMMMMMN.      MMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMMMM%           WMMMMMMMMMMMMM.            ?MMMMMMMM.     .MMMMMM.      MMMMMMMMMMMMMMM]      JMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMMM#      ,      WMMMMMMMMMMMM]      ,       ?MMMMMM]      MMMMMM[      dMMMMMMMMMMMMMM]      (MMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMMMF     .M,      TMMMMMMMMMMMb      dh.       TMMMM@      (MMMMMb      (MMMMMMMMMMMMMM%      JMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMMM`     dMMe      ?MMMMMMMMMMN      .MMa.       TMMM.     .MMMMMN      .MMMMMMMMMMMMM#       MMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMMF     .MMMMe      JMMMMMMMMMM|      MMMMe.       TM[      MMMMMM;      MMMMMMMMMMMM@       -MMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMM!     .MMMMMp      ,MMMMMMMMMb      dMMMMMx       ,E      JMMMMMb      JMMMMMMMMM"`       .MMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMF      dMMMMMMp      ,MMMMMMMMN      .MMMMMMN,             .MMMMMN      ."""7!           .dMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMM\     .MMM""""7`      .MMMMMMMM-      MMMMMMMMN,            MMMMMM,                    .dMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMM#                        WMMMMMM]      MMMMMMMMMMN,          dMMMMM]              ...JMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMM]                         UMMMMMN      (MMMMMMMMMMMN,        .MMMMMF  .....JggMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMM       .....JggMMMMp       7MMMMM.     .MMMMMMMMMMMMMm.   ....MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMF      .MMMMMMMMMMMMMp       ?MMMM)      dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMM!      dMMMMMMMMMMMMMMb       ,MMML....+gMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM             ..                                        //
//                MMMMMMMMMMMMMMMMMF      .MMMMMMMMMMMMMMMMa..(ggNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM .....JggMMMMMb                                        //
//                MMMMMMMMMMMMMMMMM'      .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM""""7!   MMMMMMMMMMMMMMN                                        //
//                MMMMMMMMMMMMMMMMN...+gNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM,        MMMMMMMMMMMMMMM_                                       //
//                MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMB"`           ?YMMMMMMMMb        MMH""""!`                                              //
//                MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMYMMMMMMMMMMM"`                  ?MMMMMMN      .M                                                       //
//                MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMH"""7!`     dMMMMMMMM"         .....         TMMMMM;      M                                                       //
//                MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM#"""7!                  (MMMMMMM'      ..MMMMMMMMN,       JMMMMb      J       .....&gb                                        //
//                MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM""""?` MMMMMN                     ...MMMMMM'      .MMMMMMMMMMMMp...gMMMMMMMN      .ggNMMMMMMMMMMMN                                        //
//                MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.      dMMMMM;       .....(ggMMMMMMMMMMMMMF      .MMMMMMMMMMMMMMMMMMMMMMMMMM.      MMMMMMMMMMMMMMM-                                       //
//                MMMMMMMMMMMMMMMMMMMMMMMMMM""""7!           ?YMMMMMM]      (MMMMMb      JMMMMMMMMMMMMMMMMMMMMM!      dMMMMMMMMMMMMMMMMMMMMMMMMMM]      dMMMMMMM""""7?!`                                       //
//                MMMMMMMMMMMMMMMMMMMMM,                        TMMMM#      .MMMMMN      .MMMMMMMMMMMMMMMMMMMMM       MMMMMMMMMMMMMMMMMMMMMMMMMMMN      P`                                                     //
//                MMMMMMMMMMMMMMMMMMMMMb             ....        ?MMMM.      MMMMMM-      MMMMMMMMMH"""! HMMMMM.      MMMMMMMMMMMMMMMMMMMMMMMMMMMM.     H                                                      //
//                MMMMMMMMMMMMMMMMMMMMMM.      gMMMMMMMMMMp       MMMM]      JMMMMM]      ?7`            (MMMMM;      (MMMMMMMMMMMMMMMMMMMMMMMMMMM[     M-                .                                    //
//                MMMMMMMMMMMMMMMMMMMMMM]      MMMMMMMMMMMM[      (MMM@      .MMMMMN                     .MMMMMb       MMMMMMMMMMMMMMMF      .MMMMb     M]    .....JggMMMMN                                    //
//                MMMMMMMMMMMMMMMMMMMMMMb      (MMMMMMMMMMMF      (MMMM       MMMMMM.           .....+gNNMMMMMMM,      .MMMMMMMMMMMMMM^      -MMMMN     MNMMMMMMMMMMMMMMMMM;                                   //
//                MMMMMMMMMMMMMMMMMMMMMMN      .MMMMMMMMMM@       dMMMM|      dMMMMM]      dMMMMMMMMMMMMMMMMMMMMN,       TMMMMMMMMMM#'      .MMMMMM;    MMMMMMMMMMMMMMMMMMMb                                   //
//                MMMMMMMMMMMMMMMMMMMMMMM|      MMMMM"""^        -MMMMMF      .MMMMMb      (MMMMMMMMMMMMMMMMMMMMMN,        _""HH""^        .MMMMMMM]    MMMMMMMM""""?`                                         //
//                MMMMMMMMMMMMMMMMMMMMMMMb                     .MMMMMMMN       MMMMMN      .MMMMMMMMMMMMMMMMMMMMMMMm.                    .JMMMMMMMMb..(g!`                                                     //
//                MMMMMMMMMMMMMMMMMMMMMMMN                  .(MMMMMMMMMM<      MMMMMM|      MMMMMMH"""7!`    -MMMMMMMN,               ..MMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMMMMM-      .....JgNMMMMMMMMMMMMMMM]      (MMMMMb                       .MMMMMMMMMMMN+.......+gMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMMMMM]      dMMMMMMMMMMMMMMMMMMMMMM#      .MMMMMN                       .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMMMMMN      -MMMMMMMMMMMMMMMMMMMMMMM.      MMMMMM.         ....(&gNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMMMMMM.     .MMMMMMMMMMMMMMMMMMMMMMM)      -MMMMM&.(ggMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMMMMMM[      HMMMMMMMMMMMMMMMMMMMMMML..+gNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMMMMMMF      -MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMMMMMM#  .....MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                       //
//                """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""`                                                      //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WANDP is ERC1155Creator {
    constructor() ERC1155Creator("Wall and Piece", "WANDP") {}
}
