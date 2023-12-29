// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Qaid's Quests: The Past Masters
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                           .00000000.                                                           //
//                                                           ;XMMMMMMX;                                                           //
//                                                           ;XMMMMMMX;                                                           //
//                                                           ;XMMMMMMX;                                                           //
//                                                           ;XMMMMMMX;                                                           //
//                        ..                                 ;XMMMMMMX;                                  ..                       //
//                      'l00c.                               ;XMMMMMMX;                                .:OKd,                     //
//                    .xXWMMWKd,                             'kKKKKKKk'                              .l0WMMMNk,                   //
//                    .dKWMMMMMNx;.                           ........                             ,dKWMMMMMXx'                   //
//                      .c0WMMMMMNk:.                                                           .;xNMMMMMWKd,                     //
//                        .cOWMMMMMW0l.                                                       .ckNMMMMMW0l.                       //
//                          .;xNMMMMWK;                                                       'OWMMMMNOc.                         //
//                             'dXNOc.                .''''cxxxxxxxxxxxxc''''.                 .;xNXx;.                           //
//                               .,.              .,cdONNNNWMMMMMMMMMMMMWNNNNOdc,.                ''                              //
//                                            ..;kXNWMMMMMMMNXKKKKKKKKXNMMMMMMMWNXk;..                                            //
//                                          .oOKNMMMMWN0dooo;..........;oood0NWMMMMNKOo.                                          //
//                                        'dXMMMMWWXx:..                    ..:xXWWMMMMXd'                                        //
//                                      .oNMMMMW0l,.                            .,l0WMMMMNo.                                      //
//                                    .:kNMMMNOc.                                  .cONMMMNk:.                                    //
//                                   .dWMMMMNd.                                      .dNMMMMWd.                                   //
//                                  .dWMMMMO,                                          ,OMMMMWd.                                  //
//                                 .dNMMMWk'                                            'kWMMMNd.                                 //
//                                 .OMMMMX;                                              :XMMMMO.                                 //
//                                .xNMMMNx.                                              .xNMMMNx.                                //
//     .okkkkkkkkkkkkkkko.        ,KMMMM0'                                                '0MMMMK,        .okkkkkkkkkkkkkkko.     //
//     '0MMMMMMMMMMMMMMMK,        ,KMMMM0'                                                '0MMMMK,        ,KMMMMMMMMMMMMMMM0'     //
//     ,0MMMMMMMMMMMMMMMK,        ,KMMMM0'                                                '0MMMMK,        ,KMMMMMMMMMMMMMMM0,     //
//     .:lllllllllllllll:.        ,KMMMM0;                    ........                    ;0MMMMK,        .:lllllllllllllll:.     //
//                                .oXMMMW0,                  'kKKKKKKk'                  ,0WMMMXo.                                //
//                                 .kMMMMX:                  ;XMMMMMMX;                  :XMMMMk.                                 //
//                                 .lXMMMW0,                 ;XMMMMMMX;                 ,0WMMMXl.                                 //
//                                   cXMMMMKl.               ;XMMMMMMX;               .lKMMMMXc                                   //
//                                    :KWMMMWO,              ;XMMMMMMX;              ,OWMMMWK:                                    //
//                                     .oXMMMWXx,            ;XMMMMMMX;            ,xXWMMMXo.                                     //
//                                      .:OWMMMMNkl:.        ;XMMMMMMX;        .:lkNMMMMWO:.                                      //
//                                        .:ONMMMMMW0o:'     :XMMMMMMX:     ':o0WMMMMMNO:.                                        //
//                                           ;okKMMMMMMN0OOOOKWMMMMMMWKOOOO0NMMMMMMXko;                                           //
//                                              .lk0NMMMMMMMMMMMMMMMMMMMMMMMMMMN0kl.                                              //
//                              .:c'               .,:d00O0NMMMMMMMMMMMMN0000d:,.                .cc.                             //
//                            .:OWWXx,                    .,cxNMMMMMMNxc,.                     'o0WW0l.                           //
//                          .o0WMMMMMX;                      ;XMMMMMMX;                       ,0WMMMMWKd'                         //
//                        'dXWMMMMWXx;.                      ;XMMMMMMX;                        ,oKWMMMMMNx;.                      //
//                     .:xXMMMMMWKo'                         ;XMMMMMMX;                          .l0WMMMMMNOc.                    //
//                    'OWMMMMMW0c.                           ;XMMMMMMX;                            .:kNMMMMMWK;                   //
//                    .cONMMNk:.                             ;XMMMMMMX;                              .,dXMMW0l.                   //
//                      .;xx,                                ;XMMMMMMX;                                 'dkc.                     //
//                                                           ;XMMMMMMX;                                                           //
//                                          .:cccccccccccccccxNMMMMMMNxccccccccccccccc:.                                          //
//                                          :NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:                                          //
//                                          :NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:                                          //
//                                          ,xOOOOO-Brushes-Should-Honor-The-TruthOOOOx,                                          //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract QQTPM is ERC1155Creator {
    constructor() ERC1155Creator("Qaid's Quests: The Past Masters", "QQTPM") {}
}
