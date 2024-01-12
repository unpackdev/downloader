
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Who is Veronica
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                     ..';:ccllllllc:;'.                                                                       //
//                                                                .;cdk0XNWMMMMMMMMMMMWN0l. ';'.                                                                //
//                                                            .;oOXWMMMMMMMMMMMMMMMMMMMMMWo.cNN0d:.                                                             //
//                                                         .,dKWMMMMMMMMMMMMMMMMMMMMMMMMMMX::NMMMWKd,                                                           //
//                                                       .:ONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMdcXMMMMMMNx,                                                         //
//                                                      ;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMOxNMMMMMMMMNx'                                                       //
//                                                    .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKKWMMMMMMMMMMKc.                                                     //
//                                                   .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMNx.                                                    //
//                                                  .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO'                                                   //
//                                                 .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO.                                                  //
//                                                 oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNXXXXXXXNNWWMMMMMMMMMMMMWd.                                                 //
//                                                :XMMMMMMMMMMMMMMMMMMMMMMMN0dl:;,,'.........'',;:lok0NMMMMMMN:                                                 //
//                                               '0MMMMMMMMMMMMMMMMMMMMWKxc'.                        .'l0WMMMMx.                                                //
//                                               cOKNMMMMMMMMMMMMMMMWKd;.                               .kWMMWk.                                .';'            //
//        .,;'.                                 ....,xNMMMMMMMMMMMXx:.                          .';,'.   .;::;.                          ..      .'.            //
//       ;l:codc.                   ...'',;:,. 'o'    ,llllcc::col'      .;l:.             .,ldxo;.... ..';c:..        .':oo'            .ckxdd;.               //
//       ..   'kk'             'oOOOOOO0KKx,   .:l:;;llodddxoc'.      .:oox0XO:.    .,lc.    .kX:    .';kNW0,      .':odolcld:            cNWWWo                //
//             '00,    .,',;,...xMKc''....       ...dWMKc'';xNN0x,  .;lc'  .,xX0c'.   'kKd.   :Kl       dMWc      :ON0:. .. .o:          .xNkOM0'               //
//              lWO'   .kWXo.   dMk.                :NNl    oWMNk:..x0;       lNWNd.   ,0MK:. .kO'     .dMK,     lNM0'   'c;;c.          ;KO':NWl               //
//              ,KWd.  '0Wd.    oW0'  ..            ;XK,   '0MNl   lWX;       .OMMK,   .xWNXx. dN:     .kMO.    ,0MK;     .'.           .xNc .OMO'              //
//              .dMK,  ;Kk.     oMXl:xKKl.          ;XO.  .dWXc    lWWl       '0MM0,   .xNolK0,cXl     '0Mk.    cNMk.                   cXO;..cNNc              //
//               :NWl  d0,      lWW0xdc::'          oW0,'dKKd'     ;KMd       ;XMMO.   '0O. 'O0xKx.    '0Md     oMMk.               ,:lkNNkolcoXMk.             //
//               '0Mk.;0c       cNX:                dM0,.xWK;      .dWO.      ;XWNo    ;Xx.  .oNMK,    '0Md.    cNMK;          ..    .cXNl    .dWNc             //
//               .kMOckk.       lWX:                oMk. ,KWx.      .xX0o,.  .oNkc.    oWx.    ;0Wo    ;XMO.     :KWx.         ;o.   .OWd.     '0Mk.            //
//               .kMNXK;        oWWo'::;'.    ,;   ;0WOc..:KWx.       ,o0N0l:dkc.     .kX:      .xO,   lNMK,      .dKk;.      'kK:  .kNx.       dWXc            //
//               lXNXXO:.     .;dkdllxO000Oxol:..':c:,...  ,OW0c. .'.   .;kN0:.     ..cX0'        :c..;odxxdc'      'okkdlllolcldc;c00c.       .:kkd:'..        //
//              .,,'.....     ..       ..,:cc;...;cc:::'    .ckOxlc:.      ,,       ..;cc'         ..      .,:'...     .,:::,.  .;cl;.         .    ....        //
//                                           'x0XWMMNkccool:;',;c;.       .lkd:.                       'llc:::;,..                                              //
//                                           cWMMMMXc.oNMMMWXXNNNK:       .okNWXkdl'...,coxxc.        ,0MMMMMMWNKo.                                             //
//                                           :NMMMMx.:XMMMMWkdXMMMO'..      .'lOWMMN00XWWNKko'       :KWMMMMMMMMMN:                                             //
//                                           ,KMMMM0,'OWMMMNocKMMMKcdd.   ';lxOXWMWX00XWNOc.       .dNMMMMMMMMMMMMx.                                            //
//                                           .xMMMMW0c;cclc;:OWMMMKoOWo  .l00kdl:;,.. .;okOd'    .lKWMMMMMMMMMMMMM0'                                            //
//                                            cNMMMMMWXkdddONMMMMMX0NMd    ..             .'...:xXMMMMMMMMMMMMMMMMK,                                            //
//                                            .dWMMMMMMMMMMMMMMMMMMMMK,                 .,;ldOk0MMMMMMMMMMMMMMMMMMO'                                            //
//                                             .xWMMMMMMMMMMMMMMMMMMK;                 cXWMMMWodWMMMMMMMMMMMMMMMMWo                                             //
//                                              .cKWMMMMMMMMMMMMMWXd.                  cNMMMMWl;XMMMMMMMMMMMMMMMWk.                                             //
//                                                .cxKWMMMMMMWWXxc.                    .kMMMMMx.dWMMMMMMMMMMMMMWk.                                              //
//                                                   ,00l:::;,oc                        'kWMMMNc'xWMMMMMMMMMMW0c.                                               //
//                                                   .dx.     ::                         .:kNMMNd;c0WMMMMMWXk:.                                                 //
//                                                    lx.     lo.                           ':okOxlldkK0dl;.                                                    //
//                                                    lO.    '00'                                .....:,                                                        //
//                                                    dK,    dWNl                                     c:                                                        //
//                                                   '0Wl    cXMx.                                   .xk.                                                       //
//                                                  .dWMk.    ';.                                    cNX;                                                       //
//                                                  :NMMNc                                           'dc.                                                       //
//                                                  oWMMMk.                                                                                                     //
//                                                  ,0MMM0'                                                                                                     //
//                                                   .lxx;                                                                                                      //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VERO is ERC721Creator {
    constructor() ERC721Creator("Who is Veronica", "VERO") {}
}
