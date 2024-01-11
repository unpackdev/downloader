
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Salvare
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//       .                                                                                                                                               .      //
//      :O:                                                                                                                                             :O:     //
//      .'.                                                                      .                                                                      .'.     //
//                                                                           ,c::::cc,                                                                          //
//                                                                         .dKx:'..:xKx.                                                                        //
//                                                                 ... .:cckXx:::;:::kNkcc:. ...                                                                //
//                                                             'ccd0x:okc.'cllc'   .lllc'.lxl:k0dcc'                                                            //
//                                                             l0l;od,ck,.:; .,:. .:,. ::.,kc,do;lOl                                                            //
//                                                         ..,;c0k;,,..;:cxc.';.   .,'.cxcc;..,,;k0c;,..                                                        //
//                                                      ,looollcccllc;.   .xo,o,   ,o,lx'   .;cccccclloool,.                                                    //
//                                                   .cdo;.               .oOll'   'llOl                .;odc.                                                  //
//                                               'ldxko.                  ;Ok;,.   .,;kO;                  .okxdl'                                              //
//                                             ,ddcxO;   ,l.             cxo,.l;   ;l.,oxc             .l'   ;Oxcdd,                                            //
//                                           .l0x,,k:.. 'kl            .:cc:ckx'   'xx:clc:.            lk' ..:x,,x0l.                                          //
//                                       .  .dXKl.od.;' lk.             .. ..':c:;:c:... ..             .kl ';.oo.lKXd.  .                                      //
//                                     'docloO0c  do.:' cx.                                             .xc ':.od  cKOollod,                                    //
//                                     ;k;...oo.  cd.,; .ol.                                            lo. :,.d:  .oo...;k;                                    //
//                                    ,ol'  'x: .''oo.. .ll.                  .;;,;;.                  .lo. ..ll,'. :x'  'll,                                   //
//                                  'lo'    'k:  'ccc:;,;,.                   :x;.;x:                   .,;;,:c:c'  :x.    'ol.                                 //
//                                .cx;       ld.  .:c::.                 .;;.  ,ccc,. .,;.                 .::c:.  .dl       ;xc.                               //
//                               'do'.       .lo'    .ld'               .dx,.         .,xd                'dl.    'dl.       .'od'                              //
//                              ;x:.'.         ,ol;...lx'                ox.           .xo                'xl...:lo,         .'.ck;                             //
//                             ;k;.;.            'ccccc.                 .xo.         .ox.                 .ccccc'            .;.;k;                            //
//                            ,x;.:'                                      .dd.  .''. .od.                                      .:.;d;                           //
//                           'd:.:;                                         co. 'oc..oc                                         ;:.:d'                          //
//                          .lc ,c.                                         .'. 'lc..'                                          .c, cl.                         //
//                          co..c,               ...                            'ol.                           ...               ,c..oc                         //
//                         ;x' ,c.            .,,;::::cllc:;'.   .;,            'll.           ,,.   .,;:cllc:;::,,,.            .c, 'x;                        //
//                        .xl  c;          ,,.;lolllc:;;;;:cllol,..:l;.         .,,.        .;l:..;llllc:;;;;:clllol;.',          ;c  ld.                       //
//                        cx. 'l'        .oOxooc,.            .,ldc..:c.         ..        .cc..cdl,.            .'cooxOo.        'o' 'kc                       //
//                       ;xl. ;l.       .xXOc.                   .lx:...  .::.       .;:.  ...:xl.                   .ckXx.       .o; .lx;                      //
//                     'ld:l; ;c        cKl.                       ,kl.   .lo.       .oc.    lk'                       .cKc        c; :l:dl'                    //
//                   .od:.,d, ,:    ,:. dk.                         ,Oo.   .xl       lx.   .oO,                         .kd .:,    :, 'd,.:do.                  //
//                   ;Oo;:kx. .'   .x0clx,                           oNo    ..      .'.    oNo                           ;xl:0d.   '. .xk:;oO,                  //
//                    ':c;ok'      .xO:;.                            lK:                   :Kc                            .;:Ox.      'ko;c:'                   //
//                        'kc       dx.                             ;x:                     ;x;                             .kd       cx'                       //
//                         :x;     ,ko                            .ld'  ..   .cc:::cc.   ..  'dl.                            ok,     ;x:                        //
//                          ,ooccloo:.                           .do.  ;c. .ld:.   .:dl. .c,  .od.                            ;oocclol,                         //
//                            .,;;.                              od.  .,.;dxc.       .cxd;.,.  .do                              .;;,.                           //
//                            ...                                oo.    'xo.           .ok'    .oo                                ...                           //
//                          ;oollloc'                            c0o'  .dd.             .dd.  'oOc                            'collloo;                         //
//                         lk,    ':oo;. ..                    'ox:   .dx.               .dd.  .;xo.                    ... ;oo:..   ;kc                        //
//                         :kl;;;;,..'oxxodo.               .;od:.   .dx.                 .xd.   .:do;.               .ldoxxo'..,;;;:lk:                        //
//                          .:lkXxcllc,;d;.ok;          .,codl,.     lO,                   ,Ol     .,ldoc,.          ;kl.;d;,cllcxXkl:.                         //
//                             .dk'  ';..o; ,oxdlccllollllc'        'Ol                     lO'       .'cllllllllclddo, ;o..;'  'kd.                            //
//                              .xd.     'l.  'cc;,,''.         .,'.lk.                     .kl.',.        ...',,;cc'  .o'     .dx.                             //
//                               ;0: ...  ,:.                  cd::oOc                       cOo::oc                  .c,  ... :O;                              //
//                               .xx. ':.  ''                  ;ll:,c'                       'c,;ll;                  ''  .:' .xx.                              //
//                                :O;  ;c.  .                    'ko.                         .ok'                    .  .c:  ;O:                               //
//                                .ok. .lc                        :O;                         ,O:                        ll. .kd.                               //
//                                 .dd. .ol.                    ';'xx.   .'::'.      '::'    .xd,;.                    .lo. .dd.                                //
//                                  .dx' .co'                    cl,cdoloddlcxd.   .dxclddolodc,lc                    .oc. 'xd.                                 //
//                                   .lk:  ,oc.                   ;l:::;,.   'ko  .ok'   .,;:::l;                   .co,  :kc.                                  //
//                                     ,xd,  ,cc;.                  .'.       'lc:cl'       .'.                  .;lc,  ,dd,                                    //
//                                      .:xd,  .:c;.                                                           .;c:.  ,ox:                                      //
//                                        .;ooc.  .'..                          ...                          ..'.  .col;.                                       //
//                                           .:ool:'..                          ,kc                          ..';lol:.                                          //
//                                             ;Oo,,'.                          ;kc                          ..',oO;                                            //
//                                             :O:  ..                          .c'                          ..  :O:                                            //
//                                             .cxl'';,.                         ..                        .,;,,lxc                                             //
//                                               .colc:;.             .,;,'             ',;,.             .;:cooc.                                              //
//                                                  .;lolldolc,      .;;,,;;.         .;;,,;;.      ,clodllol;.                                                 //
//                                                       ;0o...                                     ...o0;                                                      //
//                                                       ;0:     ..  .:ooo:.           .:ooo:.  ..     :0;                                                      //
//                                                        lkc.   ',,ckx,.'xd.    .    .dx'.,xO:,,.   .ckl                                                       //
//                                                         'coooc:;:dd.   ,Oc   'd;   c0,   .dd:;:coloc'                                                        //
//                                                            .,;:cc,.   'oddc. ,d; .cddo'   .,:cc;'.                                                           //
//                                                                       ,d;.;c..,..c;.;d,                                                                      //
//                                                                        .oc..     ..co'                                                                       //
//                                                                         .do.     .od.                                                                        //
//                                                                          c0,     ,Oc                                                                         //
//                                                                          .od;''';do.                                                                         //
//      .:.                                                                   .,,,,,.                                                                   .:.     //
//      :x:                                                                                                                                             ;x;     //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SLVR is ERC721Creator {
    constructor() ERC721Creator("Salvare", "SLVR") {}
}
