
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Last Cup Of Sorrow
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//    S.       .S_SSSs      sSSs  sdSS_SSSSSSbs          sSSs   .S       S.    .S_sSSs              //
//    SS.     .SS~SSSSS    d%%SP  YSSS~S%SSSSSP         d%%SP  .SS       SS.  .SS~YS%%b             //
//    S%S     S%S   SSSS  d%S'         S%S             d%S'    S%S       S%S  S%S   `S%b            //
//    S%S     S%S    S%S  S%|          S%S             S%S     S%S       S%S  S%S    S%S            //
//    S&S     S%S SSSS%S  S&S          S&S             S&S     S&S       S&S  S%S    d*S            //
//    S&S     S&S  SSS%S  Y&Ss         S&S             S&S     S&S       S&S  S&S   .S*S            //
//    S&S     S&S    S&S  `S&&S        S&S             S&S     S&S       S&S  S&S_sdSSS             //
//    S&S     S&S    S&S    `S*S       S&S             S&S     S&S       S&S  S&S~YSSY              //
//    S*b     S*S    S&S     l*S       S*S             S*b     S*b       d*S  S*S                   //
//    S*S.    S*S    S*S    .S*P       S*S             S*S.    S*S.     .S*S  S*S                   //
//     SSSbs  S*S    S*S  sSS*S        S*S              SSSbs   SSSbs_sdSSS   S*S                   //
//      YSSP  SSS    S*S  YSS'         S*S               YSSP    YSSP~YSSY    S*S                   //
//                   SP                SP                                     SP                    //
//                   Y                 Y                                      Y                     //
//                                                                                                  //
//                  sSSs_sSSs      sSSs                                                             //
//                 d%%SP~YS%%b    d%%SP                                                             //
//                d%S'     `S%b  d%S'                                                               //
//                S%S       S%S  S%S                                                                //
//                S&S       S&S  S&S                                                                //
//                S&S       S&S  S&S_Ss                                                             //
//                S&S       S&S  S&S~SP                                                             //
//                S&S       S&S  S&S                                                                //
//                S*b       d*S  S*b                                                                //
//                S*S.     .S*S  S*S                                                                //
//                 SSSbs_sdSSS   S*S                                                                //
//                  YSSP~YSSY    S*S                                                                //
//                               SP                                                                 //
//                               Y                                                                  //
//                                                                                                  //
//                  sSSs    sSSs_sSSs     .S_sSSs     .S_sSSs      sSSs_sSSs     .S     S.          //
//                 d%%SP   d%%SP~YS%%b   .SS~YS%%b   .SS~YS%%b    d%%SP~YS%%b   .SS     SS.         //
//                d%S'    d%S'     `S%b  S%S   `S%b  S%S   `S%b  d%S'     `S%b  S%S     S%S         //
//                S%|     S%S       S%S  S%S    S%S  S%S    S%S  S%S       S%S  S%S     S%S         //
//                S&S     S&S       S&S  S%S    d*S  S%S    d*S  S&S       S&S  S%S     S%S         //
//                Y&Ss    S&S       S&S  S&S   .S*S  S&S   .S*S  S&S       S&S  S&S     S&S         //
//                `S&&S   S&S       S&S  S&S_sdSSS   S&S_sdSSS   S&S       S&S  S&S     S&S         //
//                  `S*S  S&S       S&S  S&S~YSY%b   S&S~YSY%b   S&S       S&S  S&S     S&S         //
//                   l*S  S*b       d*S  S*S   `S%b  S*S   `S%b  S*b       d*S  S*S     S*S         //
//                  .S*P  S*S.     .S*S  S*S    S%S  S*S    S%S  S*S.     .S*S  S*S  .  S*S         //
//                sSS*S    SSSbs_sdSSS   S*S    S&S  S*S    S&S   SSSbs_sdSSS   S*S_sSs_S*S         //
//                YSS'      YSSP~YSSY    S*S    SSS  S*S    SSS    YSSP~YSSY    SSS~SSS~S*S         //
//                                       SP          SP                                             //
//                                       Y           Y                                              //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract LCOS is ERC721Creator {
    constructor() ERC721Creator("Last Cup Of Sorrow", "LCOS") {}
}
