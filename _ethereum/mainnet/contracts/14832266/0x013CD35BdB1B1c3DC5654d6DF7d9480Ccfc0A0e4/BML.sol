
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Behind My Lens
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00KKKXNWWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWXOxoc:,'.........................................................';:ldOXWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWXkl;.                                                                      .;d0WMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNOc.                                                                             .:OWMMMMMMMMMM    //
//    MMMMMMMMMMMMMNk;.                 ...................           ...................               .cKWMMMMMMMM    //
//    MMMMMMMMMMMWO:           .':loxkO00KKKKKKKKKKKKKKKKKO;         'kKKKKKKKKKKKKKKKKK00Okdoc'.         'OWMMMMMMM    //
//    MMMMMMMMMMNo.         .,o0NWMMMMMMMMMMMMMMMMMMMMMMMMN:         ,KMMMMMMMMMMMMMMMMMMMMMMMMNOc.        'OMMMMMMM    //
//    MMMMMMMMMXc         .:ONMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:         ,KMMMMMMMMMMMMMMMMMMMMMMMMMMWk.        :XMMMMMM    //
//    MMMMMMMMX:         'kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:         ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.       .kMMMMMM    //
//    MMMMMMMNl         :KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:         ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;       .dMMMMMM    //
//    MMMMMMWx.        cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:         ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;       .xMMMMMM    //
//    MMMMMMK,        ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:         ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'       ,0MMMMMM    //
//    MMMMMWd        .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:         ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMXc       .dWMMMMMM    //
//    MMMMMX;        ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:         ,KMMMMMMMMMMMMMMMMMMMMMMMMMNO;       .oNMMMMMMM    //
//    MMMMMO.        oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:         ,KMMMMMMMMMMMMMMMMMMWWNXKko,.       'xNMMMMMMMM    //
//    MMMMMx.       .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:         .;::::::::::::::::::;,'..         'dXMMMMMMMMMM    //
//    MMMMWo        .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:                                        .ckNMMMMMMMMMMMM    //
//    MMMMWo        '0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:                                        .;okXWMMMMMMMMMM    //
//    MMMMWo        '0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:                                            .:xXMMMMMMMM    //
//    MMMMWo        .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:         .cooooooooooooooollllcc;,'.           'dNMMMMMM    //
//    MMMMMx.       .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:         ,KMMMMMMMMMMMMMMMMMMMMMWWNKOo;.         ;0WMMMM    //
//    MMMMMO.        oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:         ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMWOc.        'OMMMM    //
//    MMMMMX;        ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:         ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.        ;KMMM    //
//    MMMMMWd.       .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:         ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo.       .dWMM    //
//    MMMMMMK,        ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:         ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'        cNMM    //
//    MMMMMMWx.        lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:         ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,        :NMM    //
//    MMMMMMMNl        .lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:         ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.        lNMM    //
//    MMMMMMMMX:         :KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:         ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc        .xMMM    //
//    MMMMMMMMMK:         'dXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:         ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.        :XMMM    //
//    MMMMMMMMMMXl.         'lOXWMMMMMMMMMMMMMMMMMMMMMMMMMN:         ,KMMMMMMMMMMMMMMMMMMMMMMMMMMWXx,         '0MMMM    //
//    MMMMMMMMMMMWk,           ':lxO0XNNWWWWWWWWWWWWWWWWWWX:         ,KWWWWWWWWWWWWWWWWWWWWWNX0kd:.          ,OWMMMM    //
//    MMMMMMMMMMMMMXd'              ...'',,,;;;;;;;;;;;;;;,.         .';;;;;;;;;;;;;;;;;,,,''..            .cKMMMMMM    //
//    MMMMMMMMMMMMMMWXd;.                                                                                .;kNMMMMMMM    //
//    MMMMMMMMMMMMMMMMMW0d:.                                                                          .;o0WMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWX0xl:,'..                                                           ..';cokKWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0OkxxddddddddddddddddddddddddddddddddddddddddddddddddxxxkO0KXNWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BML is ERC721Creator {
    constructor() ERC721Creator("Behind My Lens", "BML") {}
}
