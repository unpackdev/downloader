
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Escape From Puledo
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                         ....................        ..';::;,'.                     ..'''...                  ............           ...............             ....................                           //
//                        .xKKKKKKKKKKKKKKKKKKo.    .,okKNWWWWNX0xc.              .:ok0XXNXXKOd:.               :0KKKKKKKKKd.         .oKKKKKKKKKKKK0Oxoc,.       .lKKKKKKKKKKKKKKKKKKk'                          //
//                        .OWWWWWWWWWWWWWWWWWWx.  .;kNWWWWWWWWWWWWWKo.          'dKWWWWWWWWWWWWWKd,            .kWWWWWWWWWWX:         .xWWWWWWWWWWWWWWWWWNOl'     .dWWWWWWWWWWWWWWWWWW0'                          //
//                        .OWWWWWWWWWWWWWWWWWWx. .lXWWWWWWWK0XWWWWWWWk'       .oXWWWWWWWWWWWWWWWWWXo.          ;XWWWWWWWWWWWd.        .xWWWWWWWWWWWWWWWWWWWWXo.   .dWWWWWWWWWWWWWWWWWW0'                          //
//                        .OWWWWWWWXxlllllllll;  lNWWWWWWNd..,OWWWWWWWk.     'kWWWWWWWNkc;:xXWWWWWWWk'        .dWWWWWWWWWWWWK,        .xWWWWWWWWklldONWWWWWWWWO'  .dWWWWWWWWOlllllllll:.                          //
//                        .OWWWWWWW0'           .OWWWWWWW0'   cNWWWWWWNl    'OWWWWWWWNo.   .oNWWWWWWWk.       '0WWWWWWWWWWWWWo.       .xWWWWWWWNc   .:0WWWWWWWWk. .dWWWWWWWNc                                     //
//                        .OWWWWWWW0'           ;KWWWWWWWK,   ,xkkkkkkkc.  .xWWWWWWWWx.     ,KWWWWWWWNl       lNWWWWWX0NWWWWWO'       .xWWWWWWWNc     :XWWWWWWWX: .dWWWWWWWNc                                     //
//                        .OWWWWWWW0'           ,KWWWWWWWWO,               cNWWWWWWWX:      .lkxxxxxxkc.     .kWWWWWWx:0WWWWWNc       .xWWWWWWWNc     'OWWWWWWWWo .dWWWWWWWNc                                     //
//                        .OWWWWWWW0'           .xWWWWWWWWWXd,.           .kWWWWWWWWO.                       :XWWWWWNc.xWWWWWWk.      .xWWWWWWWNc     '0WWWWWWWNl .dWWWWWWWNc                                     //
//                        .OWWWWWWWXdcccccccc;.  ,0WWWWWWWWWWNOo,.        ;KWWWWWWWWx.                      .xWWWWWW0' cNWWWWWX:      .xWWWWWWWNc    .oNWWWWWWW0, .dWWWWWWWNkcccccccc:.                           //
//                        .OWWWWWWWWWWWWWWWWWO.   ,0WWWWWWWWWWWWNOc.      cNWWWWWWWWd.                      ,KWWWWWWx. ,0WWWWWWx.     .xWWWWWWWNl  .,xNWWWWWWWXc. .dWWWWWWWWWWWWWWWWMX;                           //
//                        .OWWWWWWWWWWWWWWWWWO.    .oXWWWWWWWWWWWWW0l.    oWWWWWWWWWo.                      oNWWWWWX:  .xWWWWWWK,     .xWWWWWWWWKkk0NWWWWWWWWKc.  .dWWWWWWWWWWWWWWWWWX;                           //
//                        .OWWWWWWWWXXXXXXXXXx.      'dKWWWWWWWWWWWWNk,   oWWWWWWWWWo.                     .OWWWWWWO'   cNWWWWWWo.    .xWWWWWWWWWWWWWWWWWWWXd'    .dWWWWWWWWNXXXXXXXX0,                           //
//                        .OWWWWWWWK:.'''''''.         .ckXWWWWWWWWWWW0,  cNWWWWWWWWd.                     :XWWWWWWd.   '0WWWWWW0'    .xWWWWWWWWWWWWWWWNKxc'      .dWWWWWWWNo''''''''..                           //
//                        .OWWWWWWW0'                    .'l0WWWWWWWWWWk. ;KWWWWWWWWk.                   .,xWWWWWWNd;;;;c0WWWWWWNl    .xWWWWWWWW0ddool:,.         .dWWWWWWWNc                                     //
//                        .OWWWWWWW0'                       .oXWWWWWWWWX: .kWWWWWWWW0'       .'''''''''. ,xKWWWWWWWWWWWWWWWWWWWWWk.   .xWWWWWWWWo                 .dWWWWWWWNc                                     //
//                        .OWWWWWWW0'           ;odddddddc.   cXWWWWWWWNc  :XWWWWWWWNc      .xNNNNNNNNO' oNWWWWWWWWWWWWWWWWWWWWWWX:   .xWWWWWWWWo                 .dWWWWWWWNc                                     //
//                        .OWWWWWWW0'           cNWWWWWWWO.   .kWWWWWWWX:  .dNWWWWWWWO'     ,0WWWWWWWNl 'OMWWWWWWWNNNNNNNNWWWWWWWWx.  .xWWWWWWWWo                 .dWWWWWWWNc                                     //
//                        .OWWWWWWWKc,,,,,,,,,'..kWWWWWWWK;   '0WWWWWWWO'   .xWWWWWWWWk'   .xWWWWWWWWx. cNMWWWWWW0c,,,,,,,dNWWWWWWK,  .xWWWWWWWWo                 .dWWWWWWWNd,,,,,,,,,,.                          //
//                        .OWWWWWWWWWNNNNNNNNW0, ,0WWWWWWW0l:lOWWWWWWWK:     .dNWWWWWWWXxod0WWWWWWWNd. .xWWWWWWWWd.       ,KWWWWWWWo. .xWWWWWWWWo                 .dWWWWWWWWWNNNNNNNNNNl                          //
//                        .OWWWWWWWWWWWWWWWWWWK,  'xNWWWWWWWWWWWWWWWNO;       .:ONWWWWWWWWWWWWWWWNO:.  ;KWWWWWWWX:        .kWWWWWWW0' .xWWWWWWWWo                 .dWWWWWWWWWWWWWWWWWWNl                          //
//                        .OWWWWWWWWWWWWWWWWWWK,   .;xKWWWWWWWWWWWXkc.          .:xKWWWWWWWWWWWKx:.   .dWWWWWWWWO'         lNWWWWWWNl .xMWWWWWWWo                 .dWWWWWWWWWWWWWWWWWWWl                          //
//                        .,cccccccccccccccccc;.      .;ldxkOkkdl:'.               .;ldxkOkkdl;.      .,cccccccc,.         .:ccccccc,  ,ccccccc:'                  'cccccccccccccccccc:.                          //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VART3 is ERC721Creator {
    constructor() ERC721Creator("Escape From Puledo", "VART3") {}
}
