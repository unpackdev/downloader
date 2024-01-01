// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: UNDER GROUND DEVILS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//       `     `  `  `  `  `  `  `  `  `  `  `  `  `.MN  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  ` .MM| `  `  `  `  `  `  `  `  `            `    //
//                                                 .MMN                                                                                                          .MMN                            `    `         //
//          `                                      (MM#                                                                                                           MMM]                                   `      //
//                                                .MMM#                                                                                                           MMMN.                                         //
//                                                (MMM#                                                                                                           MMMM]                                         //
//                                               .MMMM#                                                                                                           MMMMN                                         //
//                                               .MMMMN                                                                                                          .MMMMM;                                        //
//                                               dMMMMM                                                                                                          .MMMMMF                                        //
//                                              .MMMMMM;                                                                                                         .MMMMMN                                        //
//                                              .MMMMMM]                                                                                                         (MMMMMM.                                       //
//                                              .MMMMMMb                                                                                                         dMMMMMM}                                       //
//                                              (MMMMMMN                                                                                                        .MMMMMMM[                                       //
//                                              .MMMMMMM|                                                                                                       .MMMMMMM\                                       //
//                                              .MMMMMMMb                                                                                                       MMMMMMMM`                                       //
//                                               MMMMMMMM,                                                                                                     .MMMMMMM#                                        //
//                                               JMMMMMMMN                                                                                                    .MMMMMMMM%                                        //
//                          .                     WMMMMMMMp                                                                                                   JMMMMMMMF           .                             //
//                          MMp  .                 TMMMMMMMx                                                                                                 .MMMMMMMD          .MMN.                           //
//                          (M#  .Mm dM|            ,WMMMMMM,                                                                                               .MMMMMM@`     ..   .MMMMb                           //
//                          .MN   MM dMb    .N, .,     7WMMMM,                                                                                             .MMMMB=  .g,JMjM#   MMMMM#                           //
//                          .MM   dM-.MN    MM].MMMm,                                                                                                       ....    (M\M#.M#  .MMMMMN                           //
//                           MM.  JM].MM[   dMb.MMMMMm    MN&..                                                                                       ..JNMM#JM\    dF.MFJMF  dMMFMMM                           //
//                           MM-  .M] MMN   dM# MMMMMMN.  MMMMMMb(MNa.                                                                       .ggg..   .MMMMMFJM]   .M\.M]dM]  MMM\MMF                           //
//                           MM)  .MF MMM-  (MN MMMMMMMN  MMMMMM#JMMMMb          ...                                         .. .....        .MMMMN,   MMMMM]JM]   .# dM[MM}  MMM`JF                            //
//                           MM]  .M# dMMb  .MM MM /MMMMb MM_?7? JMMMMMb      .-MMMMM,  .MMMN,      .MMMN,   ..   .g, .,    .M# MMMMMNx      .MMMMMM,  M@    JM]   JF dM:MM`  MMM                               //
//                           MM]   M# (MMN. .MM~dM~ -MMMN.MM.    (M[?MMM,    .MMMM"MMMb .MMMMMN,  .MMMMMMMh  MM}  (M] dN    .M# MMMMMMMb     .M\ .MMN  M#    (M]   M\ MM.MM   MM#                               //
//                           MMF   MN .MMM] .MM{dM{  dMMM[dM_    (M] ,MMb   .MMMF   dMM..M@ .4Mb  MMF` .WMMb MM}  .MF dMb   .M# MM  .WMM[    .M]  ,MM; M#    .MF  .M! M#.M#   MM#                               //
//                           MMF   MM .MMMN .MM)JM[   MMMbdM!    (M]  dM#   JMM@    ."" .M#  .MN .MF     WMN MM}  .M@ dMMp  .MN MM    WMN    .M]   HMb MF    .M@  (M  M#.M#   HMN                               //
//                           MM@   MM .MMMM, MM[(M]   ,MM#dM!    (M]  MMF   MMM}         M#  .M# dM\     .MM.MM]  .MN dMMMp  MM MM    .MM.   .M]   (M# dN.... MN  d# .M#.MF   .MM[                              //
//                           MM#   MM .MMMMb MM[.M]    MMMdMMMMM.(MN&JM#    MMM          MN+NMMF MM       MM~MM]  .MN dMHMMp MM MM    .MM)   .M]   .M# dMMMM[ dM-.MF .MF.MF    HMN.                             //
//                           MM#   MM .MMFMN MM[.M]    MMMdMMMMM!(MMMM#`    MMM   .ggggJ.MMMMM" .MM       MM MM]  .MM dM{WMM,MM.MM.   .MM]   .M]   (M# dMMMM] (M].M% .M].MF    .MMh                             //
//                           MMN   MM .MMFdM|MM[.M]    MM#dM!    (M#MN.     MMM.  .MMMMM M#WN,  .MM.     .M# MMb   MM JM{ MMNMM_MM_   .MM\   .M]   (M@ MF     .MbdM: .M].MF     JMMb                            //
//                           MMN   MM .MMF.MbdM}.M]    MMFdM!    (M]MM]     JMM]     .MF M# MN.  MM]     (MF JM#  .MM JM) .MMMM!MM~   (MM!   .M\   dMF M]      MNMM  .M].Mb      HMM]                           //
//                           MMM   M# .MMF MNdM{.M]    MM%dM!    (M].MN     .MMM,   .dM\.M# .Mb  ?MMe.  .MM` .MM,.JMM (M]  JMMM{MM_  .MM#    .M{  .MM] M]      (MMM  .M].M#      .MMN.                          //
//                           MMM  .M# .MMF dMMM{.M]   .M# dM!    (M[ MM]     ,MMMa..MMF .M#  ?Mb  7MMMMMMM^   UMMMMM$ (M]   UMM)MMa(+MMM%    JM! .dMM\ M)       MM#  .M].MM       MMM]                          //
//                           MMM- .MF (MM] .MMM{.M]  .MM% dM_ .. JM} (MN      ,MMMMMM%   W"   7"!   7"""`      .""^   ."'    UM\dMMMMM#'     JMMMMMMF .Ml.      dM#   Mb MM;  .p  (MMN                          //
//                           MMM] (M] dMM\  MMM{.Mb..MMF  MMMMMM{dM!  W#^        ~!                                                          dMMMMM"  .MMMMMM;  .M#   M# dM]  MN  .MMM                          //
//                          .MMMb.MM! MMM`  MMM!(MMMMMD   MMMMMM! `                                                                                   .HHMMMM]   dF   dM (MN.J(M] (MMM                          //
//                          .MMMMMM#  MM#   JMM dMMM#'                                                                                                     -"^   .@   -M].MMMM/MM,JMMM                          //
//                       .. .MMMMMMF .MM]   .M@.MMB^                               .....(&ggNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNgggJ.....                             7    MN MMMMbdMMMMM#                          //
//                      .#   MMMMMM` (MM`                               ....JgNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNgJ...                           7HMHW?MMMMM%                          //
//                     .M\   -MMMMF                             ...JgMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNg...                         ,MMMD                           //
//                    .MM     .T"=                       ...gMMMMMMMMMMMMMMMMMMMMMMMMH""""""777?!~`               `~!??77""""""HMMMMMMMMMMMMMMMMMMMMMMMMMNg...        .MMMa,.                                   //
//                    MM#                          ..JNMMMMMMMMMMMMMMMM""""?!                                                           ?7"""HMMMMMMMMMMMMMMMMMNa,.      ?WMMNa.                                //
//                   -MMF                    ..JNMMMMMMMMMMMMMMM""`                            ....................                                ?7""HMMMMMMMMMMMMNa..    TMMMMN,.                            //
//                  .MMM]               ..&MMMMMMMMMMMMMMMMY"`                     ...-ggMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNg+....                            ?""HMMMMMMMMMNg,. (HMMMMN,.                         //
//                  JMMMN.         ..&MMMMMMMMMMMMMMMMMY=                  ...gNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNaJ..                            ?7"MMMMMMMMN&,HMMMMMN,                       //
//                  MMMMMNa....(&MMMMMMMMMMMMMMMMMM#"                ..JNMMMMMMMMMMMMMH"""""""77?!~```         ``~???7"""T""HMMMMMMMMMMMMNg-..                            ?THMMMMMMMMMMMMN,                     //
//                  MMMMMMMMMMMMMMMMMMMMMMMMMMMM"!                +MMMMM""""7!                                                       ?7"T"HMMMMN,                               7"MMMMMMMMMN,                   //
//                  MMMMMMMMMMMMMMMMMMMMMMMM"!                                                                                                                                  ...MMMMMMMMMMN.                 //
//                  JMMMMMMMMMMMMMMMMMMM#"                                                                                                                           JggggNNMMMMMMMMMMMMMMMMMMM-                //
//                   UMMMMMMMMMMMMMMM"^                                                                                                                              -7T"MMMMMMMMMMMMMMMMMM#9"`                 //
//                    ?HMMMMMMMMM9=                                                                                                                                             _!!!!`                          //
//                       _7""7`                                                                                                                                                                                 //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract UGDS is ERC721Creator {
    constructor() ERC721Creator("UNDER GROUND DEVILS", "UGDS") {}
}
