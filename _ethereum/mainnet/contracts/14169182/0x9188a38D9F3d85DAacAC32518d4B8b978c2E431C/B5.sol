
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: beeslo
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWWWNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWNWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMO:'''''''''''''''''''''''''''''''''''',,,;;:cloxOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMk.                                               .':oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNOdc'                                                 ,oKWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMXo.                                                 'kWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNl                                              .   .xWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMx.                                            ,o.   '0MMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk.                                           .dK;    dWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk.                                           :XNc    lWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk.                                          ;0MX:    oWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk.                                        .lXMMO.   .OMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk.                                      .cOWMMK;   .oWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk.                                  .,cxKWMMWO,   .oNMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk.            'ldxxxxxxxxxxxxxxxxkk0XNMMMWXk:.   ,kWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk.           lXMMMMMMMMMMMMMMMMMMMMMWNXOdc.   .,xXMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk.          '0MMWX0kdollcllllodddolc;'.    .,lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk.          :KOo;..                      'cONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk.          .,.    ..                    ..':lx0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk.             'lxO00Okoc'                     .,ckXWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk.          .:ONMMMMWWWMWNk:..                .'.  .ckNMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk.         ;OWMW0dl:;;;:lxKXXx.                'l:.   'dXMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk.        ,ONMKc.         .:dOx.                .dk;    'xNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk.         .,c'              .oc                 .xXo.   .lXMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk.                            .'.                 'OWx.    cXMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk.                                                 lWWo.    oNMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk.                   ..                            :NMK;    .OMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk.                   .oc.                          cNMWo    .dWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk.                    cKo.                        .dWMWd     oWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk.                    :XX;                        ;KMMWl    .dWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk.  .           ..   .oWWl                       ,0MMMK,    .OMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk.  ,,         cKk;.'dXMNc                      :KMMMNl     :XMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk.  .do.       :XWNXNWMNd.                    ;kNMMMNo.    .kMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMx.   ,OKd,.     'cdxkxo,                   'lONMMMWKc.    .dWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWd     'xNNKxc;..                     ..,cdONWMMMWXd'     'xWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMK;      .:ONMMWX0Oxolcc::;;;;;;::clodk0XWMMMMMMNOl'     .lKMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNKx,         .,o0NMMMMMMMMMMWWWWWMMMMMMMMMMMMMNKkl,.     'oKWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMM0l,.              .'cok0XNWWMMMMMMMMMMMWWNX0Oxo:'.     .;oONMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMx.                     ..',;:cccccccc:;;,'... ...';:lx0XWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMXxdddddddddddddddddddddddddddddddddddddddxxkkO0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract B5 is ERC721Creator {
    constructor() ERC721Creator("beeslo", "B5") {}
}
