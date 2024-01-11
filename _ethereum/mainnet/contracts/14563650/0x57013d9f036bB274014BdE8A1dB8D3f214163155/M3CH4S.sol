
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BOOTLEG MECHAS
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0dc::ldKWMMMMN0xoloxKWMWNNNNNNNXXKNWMMMMMMMMWXOxddxkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMX0kkkkO0XWMMKc.      .lKMWO;.     .cko''''''....;kOOOXMMMKl.      :KMMN0kddxOXWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNl.     ..:OK:          :Kk.         ..               cNMX;       .dNXo,.     'kWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNc         .;.   ;kOc    :,   .cxl.   .,:;.    ;l:.   :XMK;    ckO0N0,        :KWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWd.   :l.  ..   .xMMK,        :XMNl   .kMNc   'OM0'   ;XMWO:.  .;kWX:    ;xxdkNWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMk.   .'  .oc   .dWMX;        :XMWd.   oWNo   '0MX;   ;XMMWO,    cNk.   :X0l::;:xNMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMO.        ,,    ,OXx.   ..   .xWXc   .dWWo   .OMX:   ;KMWk.   ;kKNx.   lNo     '0MMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMM0'   ,xc         ...   .ll.   .,'    ,0MWd.  .kMN:   ,KMN:    .;;;,.   ,O0l.   ,KMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMK,   .:,    ;:.       .dNXo.        ,OWMMx.  .dWNc   .:ol'              .,'    oWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMK;        .cKN0dc:;:lxXWMMW0o:''',cxXMMMMk.  .oWWl        .c:,''';ld:        .oNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNd;;::ccoxKWMMMMMMWMMMMMMMMMMWWNNWMMMMMMMNOxxkXMWx........lXWWNNWWMMNOl;''';o0WMMMMMMMMMMMMMMMMMMMM    //
//    MMMKxddddddddddddddddddoodddOKkdddddddddddddONNOdddddddddddddxKXxdddONNKKklcccdXMMMMMMXxooooxKNWWMMMW0xdddddddddddxKWMMM    //
//    MMWd.                       ;d'             lXo.             '0x.   '0MMMx.   '0MMMMMNl     .dWMMMMWx.            .kWMMM    //
//    MMWd    .,,,,.    .,,,,.    ;d.    .;;;;;;;lKN:    .,;;;;;;:ckWx.   '0MMMx.   '0MMMMWx.      .OMMMMNc     ';;;;;;:xWMMMM    //
//    MMWo    ,d:,dc    ,d:,dl    ;d.   .xWWWWWWWWMNc    cNWWWWWWWWMMx.   '0MMMx.   '0MMMM0'        :XMMMNc    '0WWWWWWWMMMMMM    //
//    MMWo    ,l. cc    ;l. :c    ;d.    ,lllllllkWNc    cNMMMMMMMMMMx.   .;lll,    '0MMMX:    :;    oWMMNc    .;ccccccldXMMMM    //
//    MMWo    ,l. cc    ,l. cc    ;d.            :NNc    cNMMMMMMMMMMx.             '0MMWo.   ,kx'   .kMMWd.             cNMMM    //
//    MMWo    ,l. cc    ;l. cc    ;d.    ,lllllllkWNc    cNMMMMMMMMMMx.   .;:;:,    '0MWk.   .l;cl.   ;KMMNkoooooooc.    ;XMMM    //
//    MMWo    ,l. cc    ;l. cc    ;d.   .xWWWWWWWWWNc    cXWWWWWWWWWWx.   'o;.co.   '0MK,   .ox;cx;    lNMMMWWWWWWWK;    ;XMMM    //
//    MMWd    ,l. cc    ;l. cc    :x.    .,,,,,,,,oKc    .',,,,',,,:Ox.   'o. ;l.   '0Nc    :Kx,',.    .kWWk;,,,,,,'.    ;XMMM    //
//    MMWd.   ;l. cc    ;l. cl    :x'            .oOl.            .:Kx.   ,o. ;l.   ,0x.   ,dkl         ;K0,            .oNMMM    //
//    MMMXko:;c:. ,l;;;;c:. ,l;;;;ldc,;;;;;;;;;;;c:.,:;;;;;;;;;;;:cldo:;;;cc. 'l:;;;cdl;;;;c;;l;;;;;;;;;:dd:;;;;;;;;;:dk0WMMMM    //
//    MMMMMNkc.                                                    ..                                             .'lONMMMMMMM    //
//    MMMMMMMWKd;.                                                                                              .:xXWMMMMMMMMM    //
//    MMMMMMMMMMWKd;.                                                                                        .;dKWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMW0o,.                                           ..                                      ,o0WMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMN0o,                                         ..                                   'lONMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMNOl'                                      ..   ..                           .ckXMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNkc'          ..             .        .,'  :Ko   ..  ..               .:xXWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWXkc'.,dx:..cOd,.'''......:xc'.....:oxc.,kWk,.;:,'ld;....''......';dKWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWNXNWMWNNNWMNNNNNNNNNNNNWWNNNNNNNWWNNNWMWNNNNNNWWNNNNNNNXXXXNNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract M3CH4S is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
