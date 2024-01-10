
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Buff Monster Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                .oN0;             .:c.      .;'                                                                 //
//                                .xMMKl.           :KNd.    .xNO'    ..',;:clodxkOk;     ..',;;;;;'                              //
//                                 oWMMWO:.         ,KMK,    .xWWo.  cKXNWWWWNXKK0Ox;'cdxOKXNWWWWWWK:                             //
//                                 :XMWNWW0o,.      .xMWl     cNMOc. oWMXo:;,'...   .dWMXOxolc::;;:,.                             //
//                                 '0MXockXWN0d:'    lNMk.    '0MXO; ,KMK,           dWWd.                                        //
//                                 .kMWl  .:d0WWN0d, ;XM0'    .xWWNo .xMWl       ..  oWMd.                                        //
//                                  oWMx. .,lONMMWXo..OMX:     cNMMk. cNM0lcloxk0K0c.cNMk.                                        //
//                                  :XMXkkKNWN0xl;.  .xMWl     ,KMMK, '0MMWWNXK0kxo' :XMO,.';cldxc.                               //
//                                  '0MMMMMWXd;.      oWWd     .kMMNl  oWM0c'..      ,KMNKKNWWNXOl.                               //
//                                  .kMWKk0XWWX0xl:'..lNMx.     oWMMx. ;XM0'         .OMWKxoc;'.                                  //
//                                   oWMx. .;cdOXWWNKxkNMO.     :NMMO. .kMNl         .xMWo                                        //
//                                   :XMO'    'l0WMWXxdXM0'     ,KMMK,  lNMk.         cNMk.                                       //
//                                   '0MX; .lOXWN0d:. ,KMK,     .OMMN:  '0MX;         ,KMK,                                       //
//                                   .xMWkdKWNkl,.    '0MX:.....,OMMWl  .dWWo         .kMNl                                       //
//                                    lWMMMNx,        .OMWK0KXNXNWMMWd   :XM0'         lNMk.                                      //
//                                    ;XMW0;          .xNNKkdollooodo'   .dKk'         ,0M0'                                      //
//                                    .lko.            .'..                ..           ':'                                       //
//                                                                         .      .:l;                                            //
//         'ol.                  .,,.                     .okc.         .:k0o.   ,kWMNd.               .,. :Okdc;'..              //
//        .kMWo       'od,      .oNWk'        :kx,        ;XM0'       .c0WW0:  .lXMWWMW0;            .oXNd.oWMMWWNX0Okxxddddo;    //
//        ;XMMO.     .kMMx.     cNMMWO,      .xMM0,       ,KMK,     .:0WWO:.  ,OWWkdKMMMNx'         .xWWO, ,0MNxcldxkOKNMMMMNd    //
//        oWMMX;     lNMMk.    ;KMN0NM0;     .dMMWO'      '0MK;    .xNW0c.  .oXWKl.'0MWKXWXx,.     ;0WNd.  .xMWo    .;xXMWKo,     //
//       .OMMMWo    ;KMMMO.   .OMNo.cXMKc.    dWMMWk.     .OMX:  :x0WNd.   .xWNk'  .OMXc'oKWNO:. .lXMXc.    lNMk. .;xXWNk:.       //
//       :XMMMMO.  .xWMMM0,  .xWWx.  ;0WNk;   oWMMMWk.    .kMNc.lXMMKc      ;l;.   .OMN:  .cOXk''kNWO,      ;KMKll0WW0o'          //
//      .dWWKKMN:  lNMNWMX; 'kWWx.    .oKWNk:.lWMK0WWk.   .xMWxdNMMWx;...          .kMNc     .,oKWXd.  ...  '0MMWMMMXkl:;.        //
//      '0MXcoWMx.,0MXdOMNl;0WWx.       :KMMNllNMk;xWWk.  .dWWxlOXNNWWNXK0Okxxd:.  .kMNc    'oKWMWKxxk0KXXl .kMMWXXXXNWWWXOl.     //
//      cNMO.,KMKlxWWd'dMWdlKWWO:.    .lKWNk:.:XMO..dWWO'  oWWd. .',:codxkXMMMNx.  .kMNl   :XMMMMNXX0Okxoc. .xMWd'...',;lOWWk'    //
//     .kMNl .dWWNWM0' lWMx..l0WWO;  'kWWO;   ;XMO. .dNW0, lWMx.        .lKWNk;.   .kMNl   .c0WMWO:..       .dWWo        .xWWd    //
//     cNMO'  '0MMMNc  ;XM0'  .lKMXo;kWNd.    ,KM0'  .lXMKloNMk.       .oNW0:      .kMNc     .:OWWO;         dWWo         :NM0    //
//    .OMNl    :KMWx.  .OMNc    ,OWWNWWk.     ,KMK,    ;0WNXWMO.       oNMO'       .kMNc       .cKWXl.       oWWd         ;XMK    //
//    lNMk.     ,lc.    oWWx.    'OWMMK;      '0MX;     .xNMMM0'      ;XMK;        .kMNc         ,OWNd.      oWMd.        ,KMX    //
//    KMX:              ,KMK,     'OWWd.      .xN0,      .c0WMK,     .xMWo         .kMNc          .kWWk.     oWMd.        '0MN    //
//    dk:               .dWX:      .::.        .'.         .lxl.     '0M0,         .kMNc           .dNWd.    lWWo         .kMW    //
//                       .lc.                                        .cxc.          lKk'            .oOc     'xx,         .oX0    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BUFFS is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
