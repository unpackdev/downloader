// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Skinned Alive
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK00OOOO00KXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNOdl:,...      ...';ldOXWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWKd:.                      .;o0NMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMXx;.                             ,oKWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMXo'                                  .c0WMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNx'                                      .lXMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMXc                                          'kWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMM0;                                            .dWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMK,            .,clc'         ,loo:.             .dWMMMMMMMMMMM    //
//    MMMMMMMMMMMMNc            .kKdoOXd.     .dKxcdXO'             .kMMMMMMMMMMM    //
//    MMMMMMMMMMMMx.            cNd. ;KK,     '0O' .ONc              ;XMMMMMMMMMM    //
//    MMMMMMMMMMMN:             .o0kx00c       :OOk00l.              .lXWMMMMMMMM    //
//    MMMMMMMMMXd,                .;;,.  ....   .','.                  .c0WMMMMMM    //
//    MMMMMMMM0,                        ;0XXKo.                          .OMMMMMM    //
//    MMMMMMMNc                         cNMMWx.                           lWMMMMM    //
//    MMMMMMMNc                          ';:,.                           .dWMMMMM    //
//    MMMMMMMM0;                    .l:.       'o:.                     .dNMMMMMM    //
//    MMMMMMMMMXx:'                 .xXkc,'',:xK0;                   'lxXMMMMMMMM    //
//    MMMMMMMMMMMMNd.                 ,okOOOOkd;.                   ,KMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWd.                    ..                       'OMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWx.                                           ,0MMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWO,                                        .lXMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNd'                                     ;OWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMXd,                                .:kNMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNOl'                          .;o0WMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMNOd:.                  .,lxKWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMx.               ;OXWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMk.               lWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWN0kdolc::;;;;.                .;;;:::cloxOKNWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMXko;..                                        .';oONMMMMMMMMMMMM    //
//    MMMMMMMMWOc.                                                  'o0WMMMMMMMMM    //
//    MMMMMMM0:.                                                      .cKMMMMMMMM    //
//    MMMMMWx.                                                          .xWMMMMMM    //
//    MMMMWx.                                                            .oNMMMMM    //
//    MMMMk.                                                              .dWMMMM    //
//    MMMK;                                                                .kMMMM    //
//    MMWo                                                                  ;KMMM    //
//    MM0,                                                                  .xMMM    //
//                                                                                   //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract SKND is ERC721Creator {
    constructor() ERC721Creator("Skinned Alive", "SKND") {}
}
