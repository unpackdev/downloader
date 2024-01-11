
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mike Judge
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                       ..',;:::::::::::::;;,'..                                                         //
//                                                .';:cccccc::;,,'''''''',,;::cccccc:;'.                                                  //
//                                           .':clcc:,..                          ..,:cccc:'.                                             //
//                                       .':llc;'.                                      .';cll:'                                          //
//                                    .,llc;.                                                .;llc,.                                      //
//                                 .,loc,.                                                      .,coc,                                    //
//                               .col,.                                                            .,lo:.                                 //
//                             'lo:.                                                                  .col.                               //
//                           'lo;.                                                                      .:ol.                             //
//                         .ld;.                                                                          .:dc.                           //
//                       .:dc.                                                                              .cd;                          //
//                      .oo'                                                                                  'do.                        //
//                     ;xc.        ',,;,'.      .;;;;.  .,;;::,.  ';;;;;,.   ';;;;;'  .,;;;;;;;;;;;;,.         .cd;                       //
//                   .cd,         ;ko:::dd,    :xl;:x0l.lkc;;lOk';ko;;;lOx,'oo:::dXXo'dkc::::::::::cOk,          ;xc                      //
//                  .ld.          cx.   .d0:  cx,   :XK:od.  .kWdcx,   .OWKx:. .cKW0:'dl           .xMx.          'dl.                    //
//                 .od.           cx.    .d0ood'    :XK:od.  .kWdcx,   .x0l.  ,kNXo. .dl   .:dxxxxdxKNo.           .dl.                   //
//                .ld.            cx.     .dKd.     :XK:od.  .kWdcx,    ..  .oXNk,   .dl   .ckkkOKKd;'.             'xl                   //
//                cx'             cx.      ...      :XK:od.  .kWocx,        .oXx.    .dl         ;K0,                ,kc                  //
//               ,x:              cx.  .:.     ',   ;XK:od.  .OWocx,    .;,   :kl.   .xl   .cllllkNX:                 :Oc                 //
//              .do               cx.  :XO'   ;K0'  ;XX:od.  .OWocx,   .dWXl.  'xx'  .xl   ;0XXXXXKKd.                .d0,                //
//              :x'               lx.  :XWO:,lKM0'  ;XXcod.  .OWocx'   .OWOxo.  .ok: .xl    ....''';O0;                ,0k.               //
//             .dl                lx.  :XNdcldx0O,  :XXcod.  'OWock;   'OWl.ld,. .lOo;xo.          .xMx.                oXl               //
//             ;x,                ;doodON0,    'ooodOX0;;ooddkKKc'looddx00:  ;llodxO0xdoloddddddoodxKNd.                ;K0'              //
//             ld.                  .',,,.       ......    .....    ......      ......   .......''''''.                 .kNl              //
//            .do                                                                                                        oWk.             //
//            .xc                 ..cc..   ..::..    ..ccc.. .ccccccc:.           .';::cc::;,.  .ccccccc::::::c:.        cNK,             //
//            'x:                cxl''ox: ;xo''lkl. 'xoc''xOkoc'''''''ccc;.     'llc:,'''',ckd. lk;.'''''''''':Ol        :NNc             //
//            'x:               .oo   .OK;cx.  .dXc ;x'   lNK,.         ,cdc. .ld;.        'OO. od.           'kl        :NWl             //
//            .x:               .oo   .OXclx.  .dNl :x'   lWK,   .:cc'.   .od;od.   .:oxkxx0Nd. od.   ,xkkkkkkOK:        cNWo             //
//            .xl               .oo   .OXclx.   dNo :x'   lWX;   xW0 'dl.  .xNO,   ;0XXNX0000xllkd.   'dxxxkK0l,.        lWWo             //
//             oo.     .:cccc;  .oo.  .OX:lx.   oNo :x.   lWX;   xNl  'k:   lWk.  .kXc:k:.....:KNd.         cx.         .xMWl             //
//             :x.     ck:.'l0l .do   .OX:lx.   lNd.lx.   oWX;   xNo.,ld'   oWO.  .xk..xx:.   ,KWd.   ,cllclkk'         '0MX:             //
//             'x:     :x'  .oOolx;   '0X;;x,   .oxod;   .kMX;   cOxll:.   '0MX:   .lolx0x'   cNWd   .xNNNNWWKo;.       cNM0,             //
//              ld.    .xl    .;,.    lNK,.od.    ...    cXMX:            ,OW0xx;    .',.    ,0NNo    .'''',,,ckc      .kMMx.             //
//              'x:     'oo'        .lXNo. .ld,.       'dXN00c        ..;dXNk' ,ol,.       .lKXdko            .xl      cNMNc              //
//               cx.     .;llc:;;:lxKN0l.    ,llllcclokXNO:'ldoxdxxkOO0KX0x;.    ,loddoodxOKKx;.ckdoooollllllld0l     'OMMO.              //
//               .do.       .,ldxkkxo;.        .':loddoc,.   .'::::::;;,..         .';cllc:,.    ':clllloooooool'    .dWMX:               //
//                'xc                                                                                                lNMWd.               //
//                 ,xc                                                                                              cXMMO'                //
//                  ,xc       .',,,,,;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;;;,,,,,,.        cXMM0,                 //
//                   'dl.     ,o:,,,:xOxc,,,,,,,,,,,,,,,,,,,,,,,,,,cl;,,,,,,,,,,,,,,,,,,,,,,,,,,:dOxc,,,;do.     .oNMMK;                  //
//                    .oo.    .;dxxxkkOkkxxxxxxxxxxxxxxxxxxkxxxkxxkkkxkkxxkxxxxxxxxxxxxxxxxxxxxxkkkkkxxxkOd.    .xNMM0;                   //
//                     .cd;      .........................................................................     ;0WMWO,                    //
//                       ,dl.                                                                                .dNMMNx.                     //
//                        .cd:.                                                                            .cKWMMKc.                      //
//                          .ld;.                                                                        .:OWMMNx'                        //
//                            .ld:.                                                                    .cOWMMWO;                          //
//                              'okl'                                                                'o0WMMWO:.                           //
//                                'oOxc.                                                          .ckNMMMNk:.                             //
//                                  .ck0xc'                                                    'ckXWMMWKd,                                //
//                                     ,o0KOo;.                                            .:oONMMMWXx:.                                  //
//                                       .,oOXXOdc,..                                ..;cdOXWMMMWKx:.                                     //
//                                           ':dOXNX0kol:,'..                ..',:ldk0XWMMMMNKkl,.                                        //
//                                              ..;lx0XNWWNXK0OkkxxddddxxkkO0KXNWMMMMMWNKkdc,.                                            //
//                                                    .,:loxO0KXNWWWWWWMMMWWWNNXK0kdoc;..                                                 //
//                                                           ...'',;;;;;;;;,,'...                                                         //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MIKE is ERC721Creator {
    constructor() ERC721Creator("Mike Judge", "MIKE") {}
}
