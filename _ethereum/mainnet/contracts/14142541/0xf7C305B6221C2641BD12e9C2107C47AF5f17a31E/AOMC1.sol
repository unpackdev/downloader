
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Afterorder Manga Chapter 1
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    MMMMMMMMMMMMMMMMMMMMMMMMWX0xoc;'..            ..';coxOXWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMN0xc,.                            .cKMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWXkl,.                                .oNMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNkc.                                   .oNMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWKd,                                      lNMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMWKl.                                       cXMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMXo.                                        cXMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMWk,                                         :XMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMXl.                                         ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMK:                                          ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMM0,                                          ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MM0,                                          '0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MX:                                          'OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    Wo                      ,llllllc.  'clllllllo0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    O'                     :KMMMMMMWk. 'OWMMMMMMMMWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMM    //
//    l                     ;KMMMWNWMMWk. ,0MMMMMMMMKl,''''','';xWMMMMMMMMMMMMMMMMMMMM    //
//    '                    ,0MMMNo;OWMMWx. ,0MMMMMWWWx.         .xWMMMMMMMMMMMMMMMMMMM    //
//    .                   ,0MMMWd. 'OWMMWd. ;KMMMXolXWd.....     .xWMMMMMMMMMMMMMMMMMM    //
//                       'OWMMWx.   ,0MMMWd..kWWNl  cXWK0000O:    .kWMMMMMMMMMMMMMMMMM    //
//                      .OWMMWx.     ,0MMMNxxNMWo.   lNMMMMMMK:    'OWMMMMMMMMMMMMMMMM    //
//                     .kWMMWk.       ;KMMMMMMMWd.   .lNMMMMMMK;    'OMMMMMMMMMMMMMMMM    //
//                    .xWMMWk' .......'dNMMMNXKNNo.   .oNMMMMMM0,    ,0MMMMMMMMMMMMMMM    //
//    .              .xWMMWO' 'kXNNNNNNNWMMWd'.oNNl    .dNMMMMMM0,    ;0MMMMMMMMMMMMMM    //
//    ;             .dWMMM0, .kWMMMMMMMMMMWx.  .oNNl    .:ooooooo,     ;KMMMMMMMMMMMMM    //
//    d.            ,dkkkd,  :xkkkkkkkOXMWx.    .dWXc                   :XMMMMMMMMMMMM    //
//    K;                              :KWk.      .xWX:                   cXMMMMMMMMMMM    //
//    Wk.                            ,0MWOoooooolokNMXxooooooooooooooollldKMMMMMMMMMMM    //
//    MWd.                          'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMNo.                        'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMNo.                      .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMNx.                    .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMW0;                  .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMXd.               .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMWKl.            .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMW0l.         .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWKd,.     .lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNOl,.  lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMN0dxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract AOMC1 is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
