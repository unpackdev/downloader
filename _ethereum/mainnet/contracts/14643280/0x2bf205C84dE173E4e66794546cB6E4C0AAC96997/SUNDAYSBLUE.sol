
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TRAVIS WAS HERE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMN0xoc:;,,,,,;;:cloxOKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNkc'.                  ..,:okKNMMMMMMMMMMMMMMMMMMMMMMNXK0OOkkkkkkO000kxxxkKWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWO;                            .,cllccld0NWMMMMMMWXkdc;'..           .      .;OWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWO'          ...'''''.                   .'xWMMN0o;.                           .dXWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNkc.       'cdk0XNNKkdc'                    .dWXd,.      ...          .','         .:xXWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNx,          cXWXOxl;.                        .,l'     .,loc;.      .,lx00x,            .cxdod0WMMMMMMMMMM    //
//    MMMMMMMMMMMMNx,     .'.     ,;.         .,,'.        .,,.           :kxc.      .:xKWNOl.      ;dx:.         .kMMMMMMMMMM    //
//    MMMMMMMMMMWO;     .cOKo.           .;lool:'       .:dOOx'           .'      .ckXWW0o,      .ckKOo:.         .dWMMMMMMMMM    //
//    MMMMMMMMMNo.    .;oo:.        .;lxOOxl,.      .,cooo:'.                  .;xXWWKd;.     .;lol;.              .oXMMMMMMMM    //
//    MMMMMMMMXc      ..       .':dOXXOo;.      ..,;::,.                     'o0WWXx:.      .',,.          .,ll.     ,OWMMMMMM    //
//    MMMMMMMXc            .'cx0NN0dc'       ...''.         .'cd;          ,xXWKx:.         .             ;OWMMKc.    .dNMMMMM    //
//    MMMMMMXc          ':d0NWXkl,.          .          .'cx0NMMx.        .xKx:.                          .;OWMMWk.    .oWMMMM    //
//    MMMMNk;       .;oONWNOo;.                       .c0NMMMMM0;          ..                               .OMMMMO'    .xMMMM    //
//    MMNx,      .:xKWWKx:'                            .dNMMMWO.                               ';.          .xMMMMWx.    ;XMMM    //
//    MMk.      .xWXkl,.                                .OMMM0,                             ,lONNl          cXMMMMMX:    .kMMM    //
//    MMKc.     ,dc.                     .,lkd.         ,KMMMO.                         .,o0NMMMMNOo:;,,;:oONMMMMMMMo     oMMM    //
//    MMMX;                           .:xKWMMWk;.    .'lKMMNOc.                      .;o0WMMMMMMMMMMMMWWMMMMMMMMMMMMd.    lWMM    //
//    MMM0'                       .;oONMMMMMMMMWKkxxk0NMWXd,                      .;d0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.    lWMM    //
//    MMXc                     'cxKWMMMMMMMMMMMMMMMMMMWOc.          .'.        .,o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd.    lWMM    //
//    MX:                  .;oONMMMMMMMMMMMMMMMMMMMMWO;.        .:looc.      'o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWl     dMMM    //
//    MNo.              .cxKWMMMMMMMMMMMMMMMMMMMMMMWd.       ,lkKOd:.      .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,    .OMMM    //
//    MMW0'         .,lkXMMMMMMMMMMMMMMMMMMMMMMMMMMWk'   .;o0NMM0,         cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo     cNMMM    //
//    MMKo.       ,d0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXOk0XWMMMMMNd;'      '0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.    '0MMMM    //
//    MK,        :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMWO.    .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO'    .xWMMMM    //
//    MK:        ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l;,cOW0o'    .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk.    .xWMMMMM    //
//    MMN0xd;     ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'    ,o.     .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.    .xWMMMMMM    //
//    MMMMMMXc     'OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO'           .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;     'kWMMMMMMM    //
//    MMMMMMMNl.    .lKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo.         ;0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c.     :KMMMMMMMMM    //
//    MMMMMMMMWk'     .l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO'       .lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c.     ,kNMMMMMMMMMM    //
//    MMMMMMMMMMXo.     .;oONMMMMMMMMMMMMMMMMMMMMMMMMMWKx:.         ,xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXx;.     ,xNMMMMMMMMMMMM    //
//    MMMMMMMMMMMMKd,       .:ox0XNWMMMMMMMMMMMMMNXOxl;.      ..      .cxKWMMMMMMMMMMMMMMMMMMMMMMMN0d:.      ,xNMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNOl'         .';:cllooooolc:;'.        .ckXOc.       .,cdk0XNWMMMMMMMWWNXKOxo:'       .cONMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMN0dc,.                          .;okXMMMMWKOx:.        ..',;;:::;;,,'..        .'ckXMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWKOdl:;'....       ...';cox0XWMMMMMMMMMMMWXkl;..                       .,cd0NMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWWXKK00OOOOO00KXWMMMMMMMMMMMMMMMMMMMMMMWN0kdl:;,'.......'',;:loxOXWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNXXXXNNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SUNDAYSBLUE is ERC721Creator {
    constructor() ERC721Creator("TRAVIS WAS HERE", "SUNDAYSBLUE") {}
}
