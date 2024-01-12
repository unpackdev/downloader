
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Divine Disaster
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWXK0kxdolcc::::;;;:::cclodxkOKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0ko:,...                         ..,;cox0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKkdc,..                                       ..,cdOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0xl,.                                                   .;okXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl,.                                              ..''..       .;o0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKx:.                                                ,d0XNNXOo'    .',;:coONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXk:.                                                  :KWWWWWWWWKc..oOXNNN0d;;o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0o'                                                    .dWWWWWWWWWWXl:OWWWWWWWk. .:kNMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOc.                                                       lNWWWWWWWWWWNO0NWWWWWW0,    ,dXWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk;.                                                         .dXWWWWWWWWWWWWWWWWWW0c.      'oXMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:.                                                            .;d0NWWWWWWWWWNKOxo:.          'dXMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c.                                                                 .,xNWWWWWWXo.                 ,kNMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMNd.                           .';;,.                                   .xWWWWWWWk.                   .cKWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMW0:                           .:OXNNNKx:.                             ...'lOXWWWWNo.                     'xNMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMNx.                           .oXWWWWWWWNk,                          'oOKKOo::lxkxd,                       .lXMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMNo.                           .oXWWWWWWWWWWK:                        :0WWWWWWXkocccll:'                       :KMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMXc.               .,ldddolc:;;ckNWWWWWWWWWWWW0,                      ;0WWWWWWWWWWWWWWWWXl.                      ,OWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMK:               'o0NWWWWWWWWNNWWWWWWWWXKKNWWWWx.                    .xWWWWWWWWWWWWWWWWWNo.                       'OWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMX:              .cKWWWWWWWWWWWWWWWWWWWXd,''c0WWWK:                    :KWWWWWWWWWWWWWWWWWXc                         'OMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMNc              .lXWWWWWWWWWWWWWWWWWWWWd.;kd.;KWWWx.                  .dWWWWWWWWWWWWWWWWWWK,                          ,0MMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWd.              :KWWWWWWWWWWWWWWWWWWWWNl.dWK;;KWWWK;                  .OWWWWWWWWWWWWWWWWWWO.                           :XMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMk.              .dNWWWWWWWWWWWWWWWWWWWWNl.oNXxONWWWNl                  :KWWWWWWWWWWWWWWWWWNd.                           .oNMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMK;               .xWWWWWWWWWWWWWWWWWWWWWWx.:XWWWWWWWNo.                .dNWWWWWWWWWWWWWWWWWX:                             .kMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWd.               .oNWWWWWWWWWWWWWWWWWWWWWO',0WWWWWWWWx.                ,0WWWWWWWWWWWWWWWWWWO'                              :XMMMMMMMM    //
//    MMMMMMMMMMMMMMMMK,                 ,0WWWWWWWWWWWWWWWWWWWWWX:.xWWWWWWWWk.                cNWWWWWWWWWWWWWWWWWNl                               .xWMMMMMMM    //
//    MMMMMMMMMMMMMMMWd.                  cKWWWWWWWWWWWWWWWWWWWWNl.lNWWNXXX0c....',;:cclcc:,..c0XXNWWWWWWWWWWWWWW0,                                :XMMMMMMM    //
//    MMMMMMWWMMMMMMMX:                    :0WWWWWWWWWWWWWWWWWWWWx.:XWWXxlccoxOKXXNNWWWWWWWNKklcclkNWWWWWWWWWWWWNd.                                .OMMMMMMM    //
//    MMMMMMWWMMMMMMMO.                     .dXWWWWWWWWWWWWWWWWWWk.,KWWWNXXNWWWWWWWWWWWWWWWWWWWNXXNWWWWWWWWWWWWWK;                                  oWMMMMMM    //
//    MMMMMMMMMMMMMMWd.                       'dXWWWWWWWWWWWWWWWWO',0WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNd.                                  :XMMMMMM    //
//    MMMMMMMMMMMMMMWl                          ;OWWWWWWWWWWWWWWWO.,0WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW0,                                   ,KMMMMMM    //
//    MMMMMMMMMMMMMMNc                           ,0WWWWWWWWWWWWWWk.,KWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNl.                                   'OMMMMMM    //
//    MMMMMMMMMMMMMMX:                            lNWWWWWWWWWWWWWx.:XWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWk.                                    .OMMMMMM    //
//    MMMMMMMMMMMMMMX:                            ;KWWWWWWWWWWWWNo.lNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWK:                                     .OMMMMMM    //
//    MMMMMMMMMMMMMMNc                            .kWWWWWWWWWWWWXc.xWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNo.                                     '0MMMMMM    //
//    MMMMMMMMMMMMMMWl                             lNWWWWWWWWWWW0,'0WWWXklcldONWWWWWWWWWWWWWXkolloONWWWWWWWWk.                                      ,KMMMMMM    //
//    MMMMMMMMMMMMMMWd.                            ,0WWWWWWWWWWNo.lNWNO;     .cKWWWWWWWWWWWO;     .cKWWWWWWXc                                       :XMMMMMM    //
//    MMMMMMMMMMMMMMMO.                             lNWWWWWWWWWk',0WWO,        cXWWWWWWWWW0;        :XWWWWW0,                                       oWMMMMMM    //
//    MMMMMMMMMMMMMMMX:                             .oXWWWWWWNO,'xNWNo         'OWWWWWWWWWd.        .kWWWWWK,                                      .kMMMMMMM    //
//    MMMMMMMMMMMMMMMWd.                              ;xXWWN0l';ONWWX:         .xWWWWWWWWNl          oNWWWWXl                                      :XMMMMMMM    //
//    MMMMMMMMMMMMMMMM0,                               .'cl;.'dXWWWWK;          oXNWWWWWWX:          lNWWWWW0:.                                   .xWMMMMMMM    //
//    MMMMMMMMMMMMMMMMWo.                                 .;dKWWWWWWK;          cKNWWWWWWK;          lNWWWWWWXx,                                  ;KMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMK;                              .;d0NWWWWWWWWXc          cKNWWWWWWK;         .dWWWWWWWWWXx;.                              .kWMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWk.                            ,kNWWWWWWWWWWWWd.        .dNNWWWWWWXc         .OWWWWWWWWWWWNO:.                            lNMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNo.                          ;0WWWWWWWWWWWWWWK;        ;0WWWWWWWWWk.        lXWWWWWWWWWWWWWXo.                          ;KMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMXc                         'OWWWWWWWWWWWWWWWW0;      ;OWWWWNKKWWWNx.     .lKWWWWWWWWWWWWWWWXc                         'OMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMX:                       .oNWWWWWWWWWWWWWWWWWXkl:,;oKWWWWNx';OWWWNOc,;:oONWWWWWWWWWWWWWWWWWk.                       'kWMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMK:                      .xWWWWWWWWWWWWWWWWWWWWWWNNWWWWNKl.  .dXWWWWNNWWWWWWWWWWWWWWWWWWWWWK;                      'kWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMXc.                     cXWWWWWWWWWWWWWWWWWWWWWWWWWNx:'      ,OWWWWWWWWWWWWWWWWWWWWWWWWWW0,                     'OWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMXo.                    .lKWWWWWWWWWWWWWWWWWWWWWWWWXc.. ...  .dNWWWWWWWWWWWWWWWWWWWWWWWN0:                     ;0WMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMNx.                     ,dXWWWWWWWWWWNXK000KXNWWWWX0kxkK0xxONWWWWNK00KKXNWWWWWWWWWWNKo.                    .cKMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMW0:                      'lOXNWWWN0d:'.....;cxNWWWWWWWWWWWWWWWKd:::'..':d0NWWWWNKkc.                     .xNMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMNd.                      .';::c;.       .oc'kWWWWWWWWWWWWWWNo'o0o.     .;cc:;,..                     .:0WMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c.                                   .x0oxXNWWWWWWWWWWWNKdoKk'                                   ,xNMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNO;.                                  ':;.'x0kO0XNNKOO0o.';;.                                  'dXMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk;.                                     ld;..;Ok'.,x:                                     'oKWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:.                                   lxc. .kd. ;k;                                   ,dKWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOl.                                 lko' 'Od. :k;                                .:xXMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXx:.                              ;O0o';Ox,,xk'                             .,o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0d;.                           .,clodxxooc'                           .,lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc'.                                                           .;oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOd:'.                                                   .;lkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0xl;'.                                        ..,cdOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKkdl:,...                         ..,:cok0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXK0kxdolcc::::;;;;::cclodxkOKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract POP is ERC721Creator {
    constructor() ERC721Creator("Divine Disaster", "POP") {}
}
