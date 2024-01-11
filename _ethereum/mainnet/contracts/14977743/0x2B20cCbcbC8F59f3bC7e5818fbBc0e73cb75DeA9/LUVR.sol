
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LUVRworldwide
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kdolc::::::cloxk0NWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOdc,..                ..;lx0NMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkc'                           .'lkNMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOl.                                  'o0WMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:.                                      .lKWMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c.                                          .xNMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.                                             .lXMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc                                                 lNMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:                                                  .xWMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;                                                    ;KMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXOc                                                     .xMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo..                                                      lWMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                                                        cNMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc                                                         :NMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                                                         cNMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo                                                          lWMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWNXKOkxxdddooddxxkO0KXNWMMMMMMMMMK;                                                         .dWMM    //
//    MMMMMMMMMMMMMMMMMWN0xoc;'..               ...';:ldk0XNWMO.                                                         .OMMM    //
//    MMMMMMMMMMMMMMN0d:'.                                .':l;                                                          ,KMMM    //
//    MMMMMMMMMMMW0o,.                                                                                                   lWMMM    //
//    MMMMMMMMMNk:.                                                                                                     .kMMMM    //
//    MMMMMMMW0:.                                                                                                       ;XMMMM    //
//    MMMMMMNd.                                                                                                        .dWMMMM    //
//    MMMMMXl.                                                                                                         ,0MMMMM    //
//    MMMMNl                        ,:.          ,:.           .:' .cll:.        ,lll,.collllllllllc;.                 oWMMMMM    //
//    MMMWd.                       .x0'         .x0'           cKc 'kMMNl       ;KMMK;;XMMMMMMKl;:kWWKo.              '0MMMMMM    //
//    MMM0,                        .x0'         .x0'           cKc  ;XMM0,     .kWMNl ;XMMXxll,   :XMMWd.             lNMMMMMM    //
//    MMWd                         .x0'         .x0'           :Kc  .oWMWx.    lNMWx. ;XMMx.      oWMMMk.            'OMMMMMMM    //
//    MMN:                         .x0'         .x0'           cKc   .OMMNc   ;KMM0,  ;XMMXxl:,'.:KMMMK:             lNMMMMMMM    //
//    MMX;                         .x0'         .x0'           :Kc    ;KMM0, .kWMNc   ;XMMMMMWWNXNWMNx'             '0MMMMMMMM    //
//    MMX;                         .x0'         .x0'           cKc     oWMWd.lNMWx.   ;XMMNxllllld0WWKl.            oWMMMMMMMM    //
//    MMNc                         .x0'          o0,           lK;     .kMMN0XMM0,    ;XMM0,      .kWMNl           ,KMMMMMMMMM    //
//    MMWx.                        .x0'          'Od.         ,Od.      ;KMMMMMXc     ;XMM0,       cNMMx.         .dWMMMMMMMMM    //
//    MMMX:                        .xKl,,,,,,,,,,.,odc,.....;ldc.        oNMMMWd.     ;XMM0,       ,KMMO.         :XMMMMMMMMMM    //
//    MMMMO'                        ,ccc:cc:c:ccc,  .;cccccc:,.          .:lll:.      .:ll:.       .;ll:.        .kWMMMMMMMMMM    //
//    MMMMWk.                                                                                                    cNMMMMMMMMMMM    //
//    MMMMMWO,                                                                                                  .OMMMMMMMMMMMM    //
//    MMMMMMMXo.                                                                                                lNMMMMMMMMMMMM    //
//    MMMMMMMMW0l.                                                                                             '0MMMMMMMMMMMMM    //
//    MMMMMMMMMMWKd,.                                                                                         .dWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMNOo;.                                                                                      ;KMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWKxc,.                                                                                 .dWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNKko:'.                                                                            ;KMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWNKkdl;'.                                                                     .xWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxol:,..                                                             ;KMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKOkdlc:,...                                                  .dWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNX0Okdol:;,....                                      ,KMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXXKOkxdlc:;,...                          lWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXKOkxolc;,'..              .kMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXKOkdlc;'..     ;XMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0kdl:;xWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LUVR is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
