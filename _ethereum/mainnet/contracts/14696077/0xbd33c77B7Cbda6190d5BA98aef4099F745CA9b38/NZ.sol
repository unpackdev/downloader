
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nouns Zone
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxddddddddddddddddddddddddddddddddddddxKMMMMMKxdddddddddddddddddddddddddddddddddddxKWMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl                                     .dWMMMWd.                                    lNMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc                                      dWMMMWd                                     cNMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc                         .'''''.      dWMMMWd                         .''''.      cNMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc                        ;KNNNNNO.     dWMMMWd                        'ONNNN0;     cNMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl                        ;XMMMMM0'     dWMMMWd                        '0MMMMX;     cNMMMM    //
//    MMMMMMMMMMMMNKKKKKKKKKKKKKKKKK0:                        ;XMMMMM0'     c0KKKKl                        '0MMMMX;     cNMMMM    //
//    MMMMMMMMMMMWd..................                         ;XMMMMM0'      .....                         '0MMMMX;     cNMMMM    //
//    MMMMMMMMMMMWl                                           ;XMMMMM0'                                    '0MMMMX;     cNMMMM    //
//    MMMMMMMMMMMWl                                           ;0NNNNNk.                                    'ONNNN0,     cNMMMM    //
//    MMMMMMMMMMMWl     .x0000000000k;                         .......      cO000Oc                         ......      cNMMMM    //
//    MMMMMMMMMMMWl     ,KMMMMMMMMMMNl                                      dWMMMWd.                                    cNMMMM    //
//    MMMMMMMMMMMWl     ,KMMMMMMMMMMNl                                      dWMMMWd                                     cNMMMM    //
//    MMMMMMMMMMMWl     ,KMMMMMMMMMMNl                                      dWMMMWd.                                    cNMMMM    //
//    MMMMMMMMMMMWl     ,KMMMMMMMMMMNl                                      dWMMMWd                                     cNMMMM    //
//    MMMMMMMMMMMWl     ,KMMWMMMMMMMNl                                      dWMMMWd                                     cNMMMM    //
//    MMMMWOocllldxdoooodl::;;:oXMMMNl                                      dWMMMWd                                     cNMMMM    //
//    MMMMNc      :XMMMM0'     .OMMMNl                                      dWMMMWd.                                    cNMMMM    //
//    MMMMX:       :XMMM0'     .OMMMNc                                      dWMMMWd                                     cNMMMM    //
//    MMMMK;        cXMM0'     .OMMMWOlccccccccccccccccccccccccccccccccccccl0MMMMM0lccccccccccccccccccccccccccccccccccclOWMMMM    //
//    MMMMK,         cXM0'     .OMMMMMMMWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNXXXNNWWMMMMMMMMMM    //
//    MMMM0,          lXK,     .OMMWXkoc;,,,,,,;:lx0WMMW0ollllkNMMMMMNkllllo0WNOdddolkWWN0kxxxOKNMMMMWKxc;,'.....',;cxKWMMMMMM    //
//    MMMM0'           lO,     .OMNx.              .:0WWl     ,KMMMMM0'     oW0,     'lc'.     .;kWMXo.               .xNMMMMM    //
//    MMMM0'            ..     .OMO.                 ,KNl     ,KMMMMMO.     lW0'                 '0Nl        ...       .xWMMMM    //
//    MMMM0'                   .OWo        ...       .xNc     ;KMMMMM0'     lW0'                 .k0'      .oKXKx'      :XMMMM    //
//    MMMM0'                   .ONc      'd0K0x,      oXc     ;KMMMMMK,     lW0'      .,;,.      .xK;      .xNMMW0occcclkNMMMM    //
//    MMMMK,      :;           .kNc     .xMMMMMO'     lX:     ,KMMMMMK,     lN0'     ,OWWW0,     .dWO,      .,codkOKNWMMMMMMMM    //
//    MMMMK,      dO'          .kNc     .OMMMMMX;     lK:     '0MMMMMK;     cN0'     lWMMMWo     .dMMKo,.          .'ckNMMMMMM    //
//    MMMMK,     .xWx.         .ONc     .OMMMMMK,     oK:     .kMMMMM0'     cN0'     oWMMMMx.    .dMMMMNKkoc:,..      .lXMMMMM    //
//    MMMMK;     .xMNo.        .ONl     .OMMMMMk.     dX:      ,kKKKk:      cNK,     lWMMMMk.    .xWNNXNNNNWWWN0o.     .dWMMMM    //
//    MMMMX;     .xMMNl        .OWo      'oxkxl'     .xN:        ...        cNK,     cNMMMMk.    .xx'.....;kNMMM0'      lWMMMM    //
//    MMMMX;     .xMMMXc       .OM0'                 '0Wl                   cNK,     cNMMMMk.    .kk.      .,clc'      .xMMMMM    //
//    MMMMX;     .xMMMMXc      .OMWk'                lNMk.           .      cNK,     cNMMMMk.    .kWx.                .oNMMMMM    //
//    MMMMXc.    .kMMMMMK:.    'OMMWKo,.          .,dXMMWOl,....':coOx' ....oWK;    .oWMMMMk.    'OMWKd;.           .cONMMMMMM    //
//    MMMMWX0OOkk0NMMMMMMN0OOkk0NMMMMMWKOkxxddddxOKNMMMMMMMWNXXXNWMMMN0O0KKKNMWKOOOO0NMMMMMN0OOOOKNMMMMWKOxolllllox0XWMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMNXXXXXXXXXXXXXXKXXXXXXXXKKNWMMMWN0kdoollllllloxkKNMMMMMMMWXXXXKK00NMMMMMWNNNNWMMMMMMMMMMMMWX0kdolllloxk0XWMMMMMMMMMM    //
//    MMMWd.........................lNMNOc'.              .,lONMMMMO,..... .xWXko:,'..';cd0WMMMMMW0o;.           ..:dXMMMMMMMM    //
//    MMMNc                         cNWd.                    .cXMMMx.       ,:.           .oNMMMKc.                  'xNMMMMMM    //
//    MMMX:                         lW0'                       oNMMx.                      .OMM0,        .';;;'.      .oNMMMMM    //
//    MMMX:                         lNo                        ,KMWx.                      .dWNl        :0NWWWN0c.     .kMMMMM    //
//    MMMNo,,;:cclllooo:.          .xXc         'codoc.        .OMWd.                       oWK,       ;KMMMMMMMNl      cNMMMM    //
//    MMMMWWWWMMMMMMMXd'         .lKWN:        cXMMMMMK:       .kMWd.       .;dxxd:.        lWO.       .cllllllll,      ;XMMMM    //
//    MMMMMMMMMMMMWXd'         .lKWMMNc       .OMMMMMMMO.      .xWWd.      .oNMMMMNc        lNx.                        ,KMMMM    //
//    MMMMMMMMMMWKo.         .oKWMMMMNl       '0MMMMMMMK,      .xWWx.      'OMMMMMMk.       lNd         .       .......'oNMMMM    //
//    MMMMMMMMW0l.         'dKWMMMMMMNc       '0MMMMMMM0,      .kMMx.      '0MMMMMMO.       lNd        c0000O00000KKXXNNWMMMMM    //
//    MMMMMMW0c.         'dXMMMMMMMMMNc       ,KMMMMMMMO.      .OMMx.      '0MMMMMMK,       lWx.       lWMMMMMMMX0000OO0XWMMMM    //
//    MMMMW0c.         'dXMMMMMMMMMMMNl       .OWMMMMMNo       '0MMk.      .OMMMMMMK,       oW0'       ;XMMMMMMNl..    .oWMMMM    //
//    MMMNd.          .;lllllloollll0Wd.       .cdkkxo;.       ,KMMk.      .OMMMMMMK,       oWNl        cKWMMMWk.       dWMMMM    //
//    MMM0'                         oW0'                       cNMMk.      .kMMMMMMK,       dWM0'        .:odd:.       .kMMMMM    //
//    MMM0'                         oWWd.                     .xWMMk.      .kMMMMMMK,      .dMMWk.                     ,KMMMMM    //
//    MMMK,                         oWMWk,                    cXMMMO.      .kMMMMMMK,      .xMMMWO,                   .dWMMMMM    //
//    MMMX:.......................',xWMMMNkc'.            ..:kNMMMMO'      ,0MMMMMMX:      .xMMMMMXd,.              .:OWMMMMMM    //
//    MMMWXKKKKKKKKKKXXXXXXXXXNNNNNNWMMMMMMMN0kxxxddooodxk0XWMMMMMMNK00OOO0XWMMMMMMWX0OOO00KNMMMMMMMN0kdooolllllooxOXWMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM by MintFace MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NZ is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
