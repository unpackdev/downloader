
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BLOOD OF RAM
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWNK0OOkkkOOKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMWXK0OOkkkO0KXNWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWKkoc,...       ..':lx0NMMMMMMMMMMMMMMMMMWKko:,...      ...,:lx0NMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMN0o;.                    .,lONMMMMMMMMMMMW0d;.                    .,lkXMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWXx;.                           ,oKWMMMMMMNk:.                           'l0WMMMMMMMMMMMM    //
//    MMMMMMMMMMXd'                                .oKWMMNx,                                .c0WMMMMMMMMMM    //
//    MMMMMMMMWk,                                    'dkd;                                    .oXMMMMMMMMM    //
//    MMMMMMMNo.                                                                                :KMMMMMMMM    //
//    MMMMMMXl.                                                                                  ,0MMMMMMM    //
//    MMMMMNo.                    ............................................                    ;KMMMMMM    //
//    MMMMWx.                    ,0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXl                     cNMMMMM    //
//    MMMMK;                     ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd                     .kWMMMM    //
//    MMMMx.                     ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd                      cNMMMM    //
//    MMMNl                      ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd                      ,KMMMM    //
//    MMMX:                      ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd                      .OMMMM    //
//    MMMX:                      :XMMMMMMMMMMMMMMN0Okkkkkkkkkkkkkkkkkkkkkkkkk:                      .OMMMM    //
//    MMMNc                      ;XMMMMMMMMMMMMMMNk;.                                               '0MMMM    //
//    MMMWo                      .c0WMMMMMMMMMMMMMMXx,                                              ;XMMMM    //
//    MMMMO.                       .c0WMMMMMMMMMMMMMMXxc;;;;;;;;;;;;;;;;;;;;;.                     .oWMMMM    //
//    MMMMNl                         .c0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd                     ,0MMMMM    //
//    MMMMMK,                          .lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd                    .xWMMMMM    //
//    MMMMMWO'                         .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd                   .oNMMMMMM    //
//    MMMMMMWO'                      .oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd                  .oNMMMMMMM    //
//    MMMMMMMW0,                   .oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd                 .dNMMMMMMMM    //
//    MMMMMMMMMKc.                :KWMMMMMMMMMMMMWXKKKKKKKKKKKKKKNWMMMMMMMMMMd                ,OWMMMMMMMMM    //
//    MMMMMMMMMMNx'               .oKWMMMMMMMMMWKl'..............lNMMMMMMMMMMd              .lKMMMMMMMMMMM    //
//    MMMMMMMMMMMWKl.               .oKWMMMMMWKl.                :NMMMMMMMMMMd             ;OWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWO:.               .oKWMWKl.                  :XMMMMMMMMMMd           'xNMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNk;                'okl.                    :KNNNNNNNNNNo         .oXMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNk;                                       ..''''''''''.       .oKWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMNk:.                                                      'dXWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNOc.                                                  ,xXMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMW0l.                                             .;kNMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWKd'                                         .cOWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;.                                    'oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOc.                               .;xXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo'                           .cONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXx;.                      'oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOc.                 .;xXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo'             .cONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXx;.        'o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOl;''',cxXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RAMBLOOD is ERC721Creator {
    constructor() ERC721Creator("BLOOD OF RAM", "RAMBLOOD") {}
}
