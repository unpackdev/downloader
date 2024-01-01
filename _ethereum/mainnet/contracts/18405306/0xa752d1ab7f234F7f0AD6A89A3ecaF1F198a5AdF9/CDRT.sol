// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CLOUD RABBIT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                       ...,                                                   //
//                                                                                                                                                       MMMMm.                                                 //
//                                                                                                                         ` ........`           JMMN,   ?MMMMN,                                                //
//         `   `   `   `   `   `   `   `   `   `   `   `   `   `   `  `  `...gMMMMMMMNg,.`   `  `  `  `  `  `  `  `  `  ..MMMMMMMMMMMMNa,    `   WMMMMN,   TMMMM,  `   `   `   `   `   `   `   `   `   `   `    //
//                                                 .....               ..MMMMMMMMMMMMMMMMMa,                          .MMMMMMMH""""MMMMMMMm,      .WMMMM,   ?MMMM,                                              //
//                                              .MMMMMMMMa.          .(MMMMM9"!      ?TMMMMMN,                      .MMMMM"`          ?UMMMMm.      TMMMM,   WNMMb                                              //
//       `  `  `  `  `  `  `  `  `  `  ` ..ggg+JMMMMMMMMMMN    `  ` .MMMM@!   .(gNa,     TMMMMh.                  .dMMM#^            ....WMMMN,      4MNMN   ,MMMM    `  `  `  `  `  `  `  `  `  `  `  `  `     //
//                                     .MMMMMMMMMMMMggHMMMM)       .MMNM^    JMMMMMMN.     TMMMN,    `     `     .MMNMt            JMMMMMMNMMMN,      MMMM[  .MMMM~                   ..gNN,                    //
//                                    .MMMMMMMMMNMNgggMMNMMm.     .MMM#`    .MMMMMMMMF      ,MMMMx      `     ` .MMMM^             JMMMMMMMMMMMb      dMMMF   (""^               ..JMMMMMMM@                    //
//                                    (MMNMHgggMMMggggMMMNMMN,    MMMM!      MMMMMMMM'       .MMMM,            .MMMM'                       dMNM;     JMNMF                  ..NMMMMMMMMMMM#                    //
//         `    `    `    `    `   `  .MMMMMMMNggggg@ggggMMMMb   .MMNF        7HMMM"          .MMMM,           JMMMt                        ,MMM]      TH"`             `.JMMMMMMMMMMMNMNMM#       `    `       //
//                                      TMMMNMM@ggMMMMNMNMMMMF   dMMM`                   ...., ,MMMN  `   `   .MMNF                 .........MMNF                    `   -MMMMMY"! -MMMNMMN#   `                //
//                                       dMMMMMggMMMMMMMMMMNB    MMM#                  .MMMMMMN,dMMM[         dMMM>        `  `     MMMMMMMMMNMMF                         .7^     JMMNMWMMM#                    //
//                                       MNMMMggNMMMNMMMMM9^     NMM#   .gMMNa.        dMMMMMMMb.MMMN        .MMN#                   """""""WMMM%              .ga,             .dMMMM'(MNM@                    //
//                                       WMMNMMMMMNMMMNMM,       MMMN  (MMMMMMMp       dMMMMMMMF JMNM[       .MMM]                          MMNM             .MMMMM,           .MMMN#` JMMMF                    //
//                                        7MMMMMMMM" 4MMMN,      dMMM< MMMMMMMM#        ?MMMMM3  .MMMN       dMMM!                         .MMMF            .MMMMMNMp         .MMMMF   dMNMF                    //
//                                           ?77!     WMMMN  ....JMNMb JMMMMMMM^                  MMMM.      MMNM          `    `  .gNNNNNNMMMM`           .MMMMBMMMMh       JMMNMD    dMMMF                    //
//                             .                       MNMMMMMMMMMMMMM.  7""B=                    (MNM]  ``  MMM# dMMb             WMMMMMMMMMNF           JMMMM3 ,MMMMN.   .MMMNM^      7"=                     //
//                         `.dMMM,                   .dMMNMNMMMMMMMMMMb           ..gNNJ,         ,MMMMMMMMMMMMM#.MMMM               ````(MMM@           dMMMM^    WMMMN, .MMMM@                                //
//                        .JMMMMM'    `           .gMMMMMMMMHkkkkkkMMMM|         .MMMMMMMb      .MMMMNMMMMMMNMNMMMMMMM                  .MMNM!         .dMMMM!      TMMMMMMMMM$                                 //
//                       .MMMMM^    .MMM,       .MMMMMMMHqkkkkkkqkkHMMMN,        MMMMMMMMM    .MMMMMMMHkkkkkkHMMMMMMMN        `  .......JMMMt         .MMMM#`        ?NMMMMN#!                                  //
//                      .MMMN@    .MMMMMF     .dMMMMMMkqkkqqkqqkqqkqMMNMN.       JMMMMMMMF  .MMMMMMkH9UVWkkqNNNqNMNMMMN.   `    JMMMMMMMMMMF         .MMMM#           ,MMNMD                                    //
//                      dMMMF    JMMMND`     .MMMNMMHMMNHkqkkqNMMMNkkMMMMb         7WMMB^  .MMMMMkkSrrrrrXqMMMMMMNMNMMMN,       ,WMMMMMMMNM`        .MMNM#              ?"`                                     //
//                     .MMMM`   JMMMM^     .dMMNMMkkMMMMNkkqkkMMMMNkqkMMMMb              .dMMMMMkkqkrrrrrwqqMMMNMMMHMMMMb             dMNM\         dMMM#                                                       //
//                     (MMM#   .MMNM!     .MMMNMHkqkMMMMMkqkqkHMMMMkqkkMMMMb           .MMMMNMMkkqkkmwwwQWkkkMMMMMMkkMMMMNMMMMNNg..  .MMMF         JMMMM`                                                       //
//                     JMNMF   MMMMt     .MMMMMqkkqkkkqkkqkkkkkkkkkqkqkkMMMMb        .MMMMBMMNNkqkkqkkkkqkqkkkqMMMMkqMMNMMMMMMMMMMMMNMMM#          WMMM!                                                        //
//                      TM9`  .MMNM     .MMMNMqkkqkqkkkkqkkqqkqkqkqkkqkkqMMMMR      .MMM#`,MMMNkkqkkqkqkkqkqqkkkkkkqkMMMN:      ?TMMMMMM\                  .gMMN&.                                              //
//                            ,MMM#     JMMNMMNHqkkqqkqkkqkkqkkqkqkkqkqkkkMMNMh    .MMM@   MMMMNqkqkkqkqkkqkkqkqkqkkNMMM#           TMMMMp                gMMMMMMMp     ..,                                     //
//                             (""     .MMNMMMMMMNHHqkqHHNNHkqkkqkkqkkqkkkkMMMMN.  (MMM`   ,MNMMNkkqkkqkqkkqkkqkqkqNMMMM'             TNMMN.             .MMMMTMMMM;  .JMMMb                                    //
//                                     MMMMNMMMMMMMMMMMMMMMMqkqkkHNNMMMMMMMMMNMMN. MMMF     ,MMMMNHqkqkkqkqkqkkqkNMMMMM'               ,MMMN.             WNMNMMNMMh+MMMMMM^         .gNa,                      //
//                                    .MMNMHkkkMMMMMNMMNMMMMkqHNMMMMMMMMMMMMMMNMMMNMMM]       TMMMMMNHHqkkqkqHNNMMMMMD                  ,MMMb              7MMMNMNMMMMNMM"           dMMMMm.                    //
//                                    dMMMNkqkkkkkkkkkkkkkqkHMMMNM#"!         7"MMMMNM[         TMMNMMMMMMMMMMMMMMM"                     JMMM.     .......   .TMMMMMY"=       .gg,    ?MMNMN,                   //
//                                    MNMMMkkqqkqkkqkqkqkqqNMMMM"                 ?YMB`            7WMMNMMNMMNM""`                       ,MNM] ..MMMMMMMMMMN, .MMNM          .MMMMMa    WMMMN.                  //
//                                   .MMNMkkqkkqkqkkqkqkqkMMNMD                                                                          .MMMMgMMMMMMMMMMMMMMMMMNMNNgJ,.      .TMMNMN,   HMMMb                  //
//                                   ,MMMMkqkkqkkqkqkkkqkMMMM^                                               ..   ...        .(..        -MMNMMMNMBOtttttXMMMMMMMMMMMMMMN,       UMMMM,  ,MNM#                  //
//                                   ,MNMMqkqkkqkkqkqkqkMMMM%                   ..,        .MN, .dMM,      .MMMb .MMMm.    .JMMMF       .MMNMMMN#OtttttttttZMMMMMHWMMMMMMMN,      TMMMN.  ,""`                  //
//                                `...MMMNkqkqkqkqkkqkqHMMMF                   ,MMMN,    .MMMMF  MMMMN,   .MMMM=  TMMMMa  .MMMMF       .MMMM?MMMNOtttttttttttttttgNNstZMMMMMx      MMNM]                        //
//                 ..,         .gMMMMNMMMMHkkkHHHkqkkqkHMMM\                    ?MMMMN, .MMNM3    ?MMMMN.MMMM@`    ,WMMMNdMMMM^       .MMMM' JMMMKttttttdMMRttttZMMM#tttdMNMM,     JMMM^                        //
//                .MMMN     .JMMMMNMMNMNMMNkW'   .WkqkkMMNM~                      TMMMMMMMM#`       TMNMMMMM3        ?MMMMMMF       .(MMMM-. ,MNM@ttttttMMMMtttttdMBZttttMMMMMMe.                               //
//                -MMM#   `.MMMMMB=~~~dMMNNqb     JkqkqHMMM;                        TMMMMMD          .MMNMMx         .dMMNMMe.     .MMMNMMMMMMMMMKtttttttVUttttttttOtttttOHMMMMMMNg,                            //
//              `.MNMMt   (MMMM5~~~~~:JMMMMHkh...(kqkkkHMNMb                `      .dMNMMMM,       .JMMNMMNMN,      .MMMMMMMMN,    ,HMH""""WMMMMNMMmytttttOggsrttQMMM#ttttttZMMMNMMMMa,                         //
//              .MMMNN.  .MMNM3~~~:~~~_MMNMNkqqkqkkqkqkkMMMMx            `        .MMNM"MMMMN,    .MMMMF 7MMMMe   .MMMM#! (MNMMN,              ?YMMMMmOtttdMMMMMMMMMMEtttttAgdMMMMMMMMMN,                       //
//          `..MMMNMMMMNxdMNMF~~:~~:~~~JMMMMHkkqkkqkqkqqHMMMMp                  .dMMM#'  ?MMMMm  dMMN#^   .WMMMN .MMMM3     TMMM#                 TMMMNstttTMMMMMNMBOtOQgMMMMMMNMMNNMMMM%                       //
//           MMMMM#TMMMMNMMMM$~~~:~~:~~_MMMMNkkqkqkkkqkkHMNMMMNJ.               MMMM"      TNMM` TMM"       (WW=  ?""         7=                   .WMMMstttttttttAggMMMMMMMMMMMHHHMMNMF                        //
//           ?MM"!    TMMNMMNb~:~~~~~:~~?MNMMHqkf!  ?HkkqMMNMMMMMMN+.......,     7"`               ...                                               WMMNytttwggMMMMMMMMMMMHHHHHHHMMMM#                         //
//                  ..MMMMNMMMN/~~:(Jg&,~dMMMNkq_    ,qkkMMMMb?YMMMMMMMMMMMMF                     .MMMp......                                        .MMMNgNMMMMMMMMMMHHHHHHHHHHHHNMMM^                         //
//                .JMMMNMMMMMMMMe~(MMMMM[(MNMMNkh,  .XkqkHMMNM,    ?"""MMMMD                      ,MMMMMMMMMMMN,                                      dMNMMMMMNMMHHHHHHHHHHHHHHHHMMMNF                          //
//               .MMMNM5<~~~TMMMMmJMMNMMR,?MMNMNkkqkkqkkqkHMMMM,     .MMNM^                        MMNMM"""WMMMM:                                     ,MMMMMMHHHHHHHHHHHHHHHHHHHMMMMM`                          //
//              .MMMM@~~~~~~~?MMMMRWMMNMMMpdMMMMNkqkqkqkkkkHMMMMm.   dMMM`                         MMMN]     ?"!                                      .MMMMHHHHHHHHHHHHHHH@HH@HHMNMMF                           //
//              MMNMF~~:~~:__~?NMMM>MMMNMMF~dMNMMHkqkkqqkqqkHMMMMMa..MMM^                          TMM#`                                              JMNMMMHHHHHHHHHH@HHHHHHHHMMMNM`                           //
//             .MMMM<~~:~(MMMNx?"B=~~7HMH5~~~WMMMNHkqK=`?7kkkkHMMMMMMMM#                                                   `    `                    .MMMNMMMMHHHH@HHHHHHHHHHHHMMMMF                            //
//             .MMMMc~~~:MMNMMN~~~~~~~~~~~~~~(MMMMNHk!    -qkqkkHMMMMNMF                                               `                            .MMM#(MMMMHHHHHHHHHHH@HHHHHNMNM!                            //
//              dMNMN_~~~dMMMMMMm~~:~:~:~~:~:~(MMNMNHL.  .dkqkqkkkkMMMMb          `                                        .MMN.,                  .MMN#` ,MMMMHHHHHH@HHHHHH@HMMMM#                             //
//              .MMMMN,~~:TMNMMMMl~~:((J-~~:~~~(MMMMNHkkkqkkkqkqkkqkMMMN                `                           `      JMMMMMMNa...       `..gMMMMD    ?MMMMHHHHHHHHHHHHHHMMNM%                             //
//                WMMMMNgJ_?WMMM8~:(MMMMM;~~~~~~(MMNMNHkqkqkqkkqqqqqHMMMb                      `                           ,MMMMMMMMMMMMMMMMMMMMMMMM"       WNMMMHH@HHHH@HHHHHMMMM                              //
//                 (HNMMMMMMx~~~~~(MMNMM#<~~:~:~~(MMMMNMMMMMMMMMMMMMMNMMMb                    `.MMN                        -MMMHHHHMMMMMMMMMMMMMB"`         ,MMNMHHHHHHHHHHHHMMNMF                              //
//                   .THMMNMF~~~~~~(T">~~~~(J+gMMMMNMMMMMMNMMMNMNMNMMMNMMMN,   `     `     ` .MMMMMb             `         dMNNHHHHHHHHHHHMMNMb              dMMMHHHHHHHHHHHHMNMM%                              //
//                     .MNMM>~:~:~~~~:((+MMMMMMMMMNMMMMMMHHHHHHHHHHHHNMNMMMMN,.           ..MMMNNMMMx         `           .MMMMHHHHHHHHHHHHMMMM;             -MNMMHHH@HH@HHHHNMMM`                              //
//                      MMMM[~~:~::(JMMMMMMMMMMMHHHHHHHHHHHHHHHHHHHHHNMMN,WMMMMNg......(gMMMMMMMHMMMMp     `           ` .MMMMHHHHHHHHHHHHHMMNMb             .MMNMHHHHHHHHHHMMMM#                               //
//                      qMNMN,~~(+MMMMMMMMMHHHHHHHHHHHHHHHHHHHHHHHHHHMMMM   7WMMMMMMMMMMMMMMMHHHHHMMMMN,               .JMMMMHHHHHHHHHHHHHHHMMMM.            .MMMMHHHHHHHHHHMMMMF                               //
//                       UMMMMNMMMMMMMMHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHMMNM-      ?"""""MMMMHHHHHHHHHMMMMMMa,.        ..MMMMNMHHHHHHH@HH@HH@HHMMMM]            .MMMMHHHH@HH@HHMNMM\                               //
//                        (HMMMMMMMMHHHHHHHHHHHHHHHHHHHHHHHHH@HH@HHHHMMMM]            dMMMMHHHHHHHHHHMMNMMMMMMNNNMMMMMMMMMHHHHHHHHHHHHHHHHHHHNMMN            (MNMMHHHHHHHHHHMMNM                                //
//                          .MMNMMMHHHHHHHHHHHHHH@HHHMY""""WMHHHHHH@HMMMN@             MNMMY"""WHHHHHHHHHMMMMMMMMMMMMMMHHHHHH#"^`   ?7YMHHHHHMMMMb          .MMMMHHHHHHHHHHMMMM#                                //
//                            TMMMMMHHHHHHHHH@HHHHY'         ,HHHHHHH!HMMM.            .MMNN.    ?MHHHHHM=  .WHHHHHM"""YHHHH#           (UHHHHMMMMp        .MMNMMHHHH@HHHHHMNMMF                                //
//                             ,MNMMMHHHH@HHHHHH#!           .MHHHHHM ,MMM]             ,MMMb      4HHHH!    .MHHHM     ,HHHN             (MHHHMMMMN,.   .dMMMMMHHHHHHHH@HHMMMN\                                //
//                              .MMNMMHHHHHHHHHM`         ..JHHHHHHH#  MMNN.             dMMMN,     WHHH_     JHHHH.     XHHH.    dMa,     ,MHHHMMMMMMMMMMMMMMHHHHHHHHHHHHHNMMM                                 //
//                                MMMMMHHHHH@HH]      .dHHHHHHHHH@HHF  -MMMb             .MNMMH,    ,HHH:     ,HHHH:     ,HHH)    (HHH;     (HHHHHMMMMMMMMMMHHHHHHHH@HHHHHMMMM#                                 //
//                                .MMNMMHHHHHHH[     .HHHHHHHHHHHHHHF   UMMMp            .MMNMH]    .HHH)     .HHHH)      HHH]    ,HHHb      HHHHHHHHHHHHHHHHHHHHHHHHHH@HHMMNMF                                 //
//                                 ,MMNMMHHHHHH]     -HHHHHHHHHHHHHH]    UMMMh.          -MMMMHF    .HHH]     .HHHH]      HHHb    .HHH#      MHHHHHHHHHHHHHHHHHHHHHHHHHHHHMMMM\                                 //
//                                  (MMNMHH@HHHb     ,HHHHHHHHHHHHHH\     MMMMMm,.    `.JMMMMHH]    .HHHb     .HHHHF      HHHM     MHHF      HHHHHHHHHHHHHHHHHHHH@HHHHHHHHMNMM                                  //
//                                   WMMMMHHHHHN.     WHHHHH@HH@HHHH}     HHMMMMMMMMMMMMMMM9HH#     .HHHM.     WHHHF     .HHHH_    d#"      .HHHHHHHH@HHHHHHHHHHHHHH@HHHHMMMN#                                  //
//                                   .MMMMMHHHHHL     .MHHHHHMHHHHHH:     HMMMMMMMMMMMMM#"  .^      .HHHH[      ?"^      .HHHH)            .HHHHH@HHHHHH@HH@HH@HHHHHHHH@HMMMM]                                  //
//                                    JMNMMHHHHHHp       ~`    ?HHHH`           4HHHHHh            .MHHHHN.             .MHHHH]          .JHHHHHHHHHHHHHHHHHHHHHH@HHHHHHHNMNM!                                  //
//                                     MMMMMHHHHHHh,           .HHHH.           .HHHHHHN,         .HHHHHHHN,           .MHHHHHHa.   ...+MHHHHHHHHHHH@HHHHHHHHHHHHHHHHHHHMMMM#                                   //
//                                     ,MNMMHHHHHHHHNa..   ...+HHHHHMa.........dHHHHHHHHHHNa(..JdHHHHHHHHHHHHNag+++ggMHHHHHHHHHHHHHHHHHHHHHHHHHH@MMMHYYYYYYWHMMMHHHH@HHHMMMNF                                   //
//                                      HMMMMHH@HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHMMYY"WMHHHHHHHHHHHHHHH@HHHHHHHHHHHHHHHHH#!                 .MHHHHHNMMM!                                   //
//                                      ,MMNMHHHHHHHHHHHHHHMY""!     ?HHHHHHHHMY""77?77"YMHHHHHHHM"!         (MHHHHHHHHHMY""""WMHHHHHHM"` _7HHb                   JHHHHMMMNF                                    //
//                                       dMMNMHHHHHHHHHHM^             ?HHHHHH'           7HHHHHM!            .MHHHHHM"         .WHHHHF     JHH,                 .HHHHHMMMM%                                    //
//                                       ,MMMMHHHHHHHHHHF         .     -HHHHH_            XHHHHM.     .+,     ,HHHHH%            4HHHb     ,HHHHHHHH)     ,HHHHHHHHHHMMNM#                                     //
//                                        dMNMMHH@HH@HHHb      .dHHb     JHHHH]     ,H]    .HHHHH[     ,H#     .HHHHH]    .HN,    .HHHN      HHHHHHHH]     ,HHHHHHHHHHMMMM]                                     //
//                                        .MMNMMHHHHHHHHN      MHHHH;    .HHHHb     .Y"     dHHHHb             ,HHHHH]    ,HH#     MHHM.     WHHHHHHHF     ,HHHHHHHHHMMNM#                                      //
//                                         dMMMMHHHHHHHHH-     ?Y""7     .HHHHN             .HHHHH.             .WHHH]      `     .HHHH|     JHHHHHHHb     -HHHHHHHHHMMMNt                                      //
//                                          MMNMMHHHHHHHHb               JHHHHM.             qHHHH]              .HHHF            HHHHHb     ,HHHHHHHN     JHHHHHHHHMMNM#                                       //
//                                          (MMMMHHH@HHHHN              JHHHHHH|     (HM[    .HHHHN     -HHN      dHHb             4HHHN.    .HHHHHHHN     JHHHHH@HHNMMM^                                       //
//                                           MMMMMHHHHH@HH[              7MHHHH]     ,HHN     WHHHH[    .HHH;     dHH@     ua..     MHHH]     WHHHHHHH     gHHHHHHHMMMMF                                        //
//                                           ,MNMNMHHHHHHHb     .J.        THHHb     .HHH[    ,HHHHN     ??!      MHHN     JHHF     dHHHN.    JHHHHHHH.    dHHHHHHMMMM#                                         //
//                                            qMMMMHHHHHHHH,     MHHm,      ,HHN      HHHN.   .HHHHH[            JHHHH.             dHHHHL    ,HHH@HHH~                                                         //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CDRT is ERC721Creator {
    constructor() ERC721Creator("CLOUD RABBIT", "CDRT") {}
}
