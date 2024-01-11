
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Trash Pepe Renaissance
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    000000000000000000000000000000000000000000000000000000000000000000000000000000d:d0000000OO000000OOO00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    00000000000000000000000000000000000000000000000000000000000000000000000000000k:,,o00000O:;k00000o'l00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    00000000000000000000000000000000000000000000000000000000000000000000000000000o:o;l00000x,.o0000k:.;kK000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    0000000000000000000000000000000000000000000000000000000000000000000000000000O:lk:l00000o:c:x000d:l:l0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    0000000000000000000000000000000000000000000000000000000000000000000000000000x:dKl:O0000ccOcc000l:Oo:ok00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    0000000000000000000000000000000000000000000000000000000000000000000000000000x:xXx:d000O:lKl:OKO:lXk:'o00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    0000000000000000000000000000000000000000000000000000000000000000000000000000o:kXKccO00x;dXo:kKx;dXKl.cO0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    0000000000000000000000000000000000000000000000000000000000000000000000000000cc0XXd;x00l:OXx;dKl:OXKo.:k0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    000000000000000000000000000000000000000000000000000000000000000000000000000OclKKXO:l0k:lKXO:oO:oKKXd,;x0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    000000000000000000000000000000000000000000000000000000000000000000000000000OclKXKKd;xx;dXXKcco:kXKXkc;o0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    0000000000000000000000000000000000000000000000000000000000000000000000000000ccKXKXKd:,:OXKXd,,oKXKXOd:l0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    0000000000000000000000000000000000000000000000000000000000000000000000000000l:OXKKXKkcdKXKXOcl0XXXX0k:c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    0000000000000000000000000000000000000000000000000000000000000000000000000000x:oKKXXKXXXXXKKXKKXXXXXK0l:O000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    000000000000000000000000000000000000000000000000000000000000Oxdooooooooooooodc;xXXKXKKXXXKXXKXXXXXKXXd;x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    0000000000000000000000000000000000000000000000000000000kdlccc::::::::::::::::;,,cokKXXXXKKXKKKXKXXKXXO:oK0OkxddddddddddddddxxkOOO00000000000000000000000000000000000000000000000000000000000000000000000    //
//    0000000000000000000000000000000000000000000000000000Ooc:;:cooooooooooooooooooool:;;:cldk0XKKXKXXXXKK0d',lc:::::::::::::::::::::::ccloxO00000000000000000000000000000000000000000000000000000000000000000    //
//    00000000000000000000000000000000000000000000000000xl;;coooooooooooooooooooooooooooolc:;;:lxKXXXKX0d:,,,;clooooooooooooooooooooooollc:::cok00000000000000000000000000000000000000000000000000000000000000    //
//    0000000000000000000000000000000000000000000000kdl:;:loooooooooooooooooooooooooooooooooool:;:d0XXO:':looooooooooooooooooooooooooooooooooc;;:lk00000000000000000000000000000000000000000000000000000000000    //
//    00000000000000000000000000000000000000000000kc;;:loooooooooooooooooooooooooooooooooooooooooc;:ld;'coooooooooooooooooooooooooooooooooooooool:;cok00000000000000000000000000000000000000000000000000000000    //
//    000000000000000000000000000000000000000000kl;:looooooooooooooooooooooooooooooooooooooooooooool:..:oooooooooooooooooooooooooooooooooooooooooooc:;lk000000000000000000000000000000000000000000000000000000    //
//    0000000000000000000000000000000000000000xc;;looooooooooooooooooooooooooooooooooooooooooooooooool:,cooooooooooooooooooooooooooooooooooooooooooool;;oO0000000000000000000000000000000000000000000000000000    //
//    00000000000000000000000000000000000000xc;:loooooooooooooooooooooooooooooooooooooooooooooooooooooo:,:oooooooooooooooooooooooooooooooooooooooooooool;;lk00000000000000000000000000000000000000000000000000    //
//    00000000000000000000000000000000000Odc;:loooooooooooooooooooooooooooooooooooooooooooooooooooooooooc,':oooooooooooooooooooooooooooooooooooooooooooool:;lk000000000000000000000000000000000000000000000000    //
//    0000000000000000000000000000000000x:;cooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo:.,looooooooooooooooooooooooooooooooooooooooooooool;;lO0000000000000000000000000000000000000000000000    //
//    00000000000000000000000000000000xc;:ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo:',cooooooooooooooooooooooooooooooooooooooooooooooool;;dO00000000000000000000000000000000000000000000    //
//    000000000000000000000000000000xc;:loooooooooolcc::::::::::::::cccclllllloooooooooooooooooooooooooool;,:ooooooooooooooooooooooooooooooooooooooooooooooooooc;:x0000000000000000000000000000000000000000000    //
//    0000000000000000000000000000kc;:loooooooooool:::::::::::::::::::::::::::::::::::clooooooooooooooooolc,;ooooooooooooooooooooooooooooooooooooooollcccc::::ccc,'oO00000000000000000000000000000000000000000    //
//    00000000000000000000000000kl;:loooooooooooooooooooooooooooooooooooooooooooollcc::::::::::cclooooooool,;ooooooooooooooooooooooooollcc::::::::::::::::::::::::;'l00000000000000000000000000000000000000000    //
//    0000000000000000000000000d;;looooooooooooooooooooooooooooooooooooooooooooooooooooooolcc::::::::cloooo;,looooooooooooollccc::::::::::::cclllooooooooooooooooooc,lO000000000000000000000000000000000000000    //
//    00000000000000000000000kc,cooooooooooooooooooooooolc::::::::::::::::::::::::cllooooooooooooooc:::::cc:',ooolc::::::::::::::cclloooooooooooooooooooooooooooooooc'cO00000000000000000000000000000000000000    //
//    0000000000000000000000o;;loooooooooooooooooolc:::::;,,;;;;;;;;;::::;::::;;;,;;:::::::::cllooooooolc:::'.'::::::cllloooooooooooooooooooooooooooooollccc:::::c:cc;.:O0000000000000000000000000000000000000    //
//    00000000000000000000kc,cooooooooooooooolc:;::::clccodxkkkkkkkxxx:.     ..........'''',,;;::::::cloooool:.,looooooooooooooooooooooooooollcc::::::::::::cccc:c::::'.o0000000000000000000000000000000000000    //
//    000000000000000000kl;:looooooooooooooooc;:loooocco0WMMMMMMMMNOl,.                      ...',,,,;::::::cl:,looooooooooolc::::::::::::::;;,,,'''',,,,,''''''''''','..,;lk000000000000000000000000000000000    //
//    00000000000000000d;;looooooooooooooooooooool:coxKWMMMMMMMMW0;                                  .';ccc:::,.;oolc:::::::::::::;:::clloddddo,                            .lk0000000000000000000000000000000    //
//    000000000000000Ol,:ooooooooooooooooooooool:cxKWMMMMMMMMMMWk.             .''.         .           ..',clc'.;:;::::::::clodddxO0KXNWWMMMXl.                              .ck00000000000000000000000000000    //
//    00000000000000k:,cooooooooooooooooooooooc:dXMMMMMMMMMMMMMk.             .xNWO'    .;dO0Oxc.            .;:',lolccoddxO0XWMMMMMMMMMMMMMXc                                  'd0000000000000000000000000000    //
//    000000000000Oo;;loooooooooooooooooooooo:c0WMMMMMMMMMMMMMWl              .oXWK;   .dWMMMMMWO,             ...;odkKNMMMMMMMMMMMMMMMMMMMWd.             .'.      .,::c:.      .cO00000000000000000000000000    //
//    00000000000x:;cooooooooooooooooooooooo:lKMMMMMMMMMMMMMMMWl                .'.    ,KMMMMMMMMk.               oWMMMMMMMMMMMMMMMMMMMMMMMNc             cXN0:    ;ONMMMWx.      .o00000000000000000000000000    //
//    000000000Ol,:oooooooooooooooooooooool:oXMMMMMMMMMMMMMMMMWl                       '0MMMMMMMNc               .c0WMMMMMMMMMMMMMMMMMMMMMMX;             ;KNXo.  .xMMMMMMX;       ,k0000000000000000000000000    //
//    00000000x:;coooooooooooooooooooooooo::0MMMMMMMMMMMMMMMMMWc                  ,c'   'd0NWNXO:                '::xNMMMMMMMMMMMMMMMMMMMMMK,              ...     cNMMMMMK;       .l0000000000000000000000000    //
//    000000kl;:ooooooooooooooooooooooooodc;OMMMMMMMMMMMMMMMMMWo                 .lO:     ..''.                 .;ol:l0WMMMMMMMMMMMMMMMMMMMX;                  ..   ,oxkxo;         ;O000000000000000000000000    //
//    0000Oo;;loooooooooooooooooooooooooooocc0MMMMMMMMMMMMMMMMMk.                                             .'cooooc:oKWMMMMMMMMMMMMMMMMMNc                 ,ko.                  ;O000000000000000000000000    //
//    000d:;looooooooooooooooooooooooooooooo:cKMMMMMMMMMMMMMMMMK;                                           .;loooooooo::xNMMMMMMMMMMMMMMMMMx.                 ..                   ;O000000000000000000000000    //
//    0xc;coooooooooooooooooooooooooooooooooo:cKMMMMMMMMMMMMMMMWd                                      ..,:cooooooooooool:ckXWMMMMMMMMMMMMMMX:                                     .l0000000000000000000000000    //
//    l;:ooooooooooooooooooooooooooooooooooooo:lXMMMMMMMMMMMMMMMK;                                  .,:looooooooooooooooool:cox0NMMMMMMMMMMMMk.                                    :O0000000000000000000000000    //
//    :looooooooooooooooooooooooooooooooooooooo:c0MMMMMMMMMMMMMMWd.                             ..,:loooooooooooooooooooooooolccldOXMMMMMMMMMNo                                  'oO00000000000000000000000000    //
//    ooooooooooooooooooooooooooooooooooooooooooc:kNMMMMMMMMMMMMMX;                          .';loooooooooooooooooooooooooooooooocccd0WMMMMMMMX;                               'oO000000000000000OO00000000000    //
//    oooooooooooooooooooooooooooooooooooooooooool:lkXWMMMMMMMMMMMKc                   ..',;cloooooooooooooooooooooooooooooooooooooocclxXWMMMMWd.                           ..'x00000000000000kdclk00000000000    //
//    ooooooooooooooooooooooooc;,,,;::clooooooooooolcloxOKXNNNNNNNNXo.            ..':cloooooooooooooooooooooooooooooooooooooooooooooolccokKNWMNo.                        .,cl,:O000000Okxoc:,.,dO000000000000    //
//    oooooooooooooooooooooooool:;;,'.....'',,,;::cclllcccloooooooool;...'''''',;:looooooooooooooooooooooolllcclooooooolooooooooooooooooolccldxO0o.                   ..,coooo:.:olc:;,...   .ck00000000000000    //
//    ooooooooooooooooooooooooooooooolc:;,'..       ......''',,,,,;;;;;;;;;;;::;;;;;;;;;;;;;;;;;,,'''''....... ,oooool'..',,;cclllooooooooooolcccc;',,,,'''''''''',,,;;;;,''...        ..';cok0000000000000000    //
//    oooooooooooooooooooooooooooooooooooooolc:;,,.....                                                       .;oooooc.       ...........'''''''''..................      ........;clodxO000000000000000000000    //
//    ooooooooooooooooooooooooooooooooooooooooooooooollcc::;;,,,''''..............................'',,,;;:::cclooooooolc:;;,,,,''''''''...................'''',,,;;;:::cccllllooc,dK00000000000000000000000000    //
//    oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooollllloooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooool,c000000000000000000000000000    //
//    oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooollllllllllc::::::::::::::::::::::::::::::::::::::::::::cccclllloooooooooooooooooooooooooooooooooooooooooooo;;x0OO00000000000000000000000    //
//    oooooooooooooooooooooooooooooooooooooooooooooooooollccc:::::;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::::::cclllloooooooooooollooollcccccc::::::;',::::cx00000000000000000000    //
//    ooooooooooooooooooooooooooooooooooooooooolc::::;;;;;;;;;;:::cccccllccllccccccccccccccccccccccccccccccccccccccccccccccccccllcccccc::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:ccccc:''d00000000000000000000    //
//    ooooooooooooooooooooooooooooooooooool;;;;;;;;;;:ccccllccccccccccccllcccccccccccccclllcllclllllllcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccllllllccc:::;;;;;,'..:k00000000000000000000    //
//    ooooooooooooooooooooooooooooooooool;,;:cccccccccccc::::;;;;;;;;;;;;;;;;;,,;;;;;;;;;;;,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::cccccccccc:cc::::::::::::::;;;;;;;;;;;,,;;;;:::;,.'d00000000000000000000    //
//    ooooooooooooooooooooooooolcoooooo:,,cccccccc:;;;;;;;;;;;;;;;;;::::::::::;;;;;;;;;;;::::::::::::cccccccccccccccccccccccc::;;;;;;;;;;;,,,,;;;;;;,;;;;;;;;;;;;;;;;:::ccccccc:;;;'':clk000000000000000000000    //
//    ooooooooooooooooooooloooc,:oooo:,,:ccccc:;;,,,;:ccllcccccccccccccccccccclllcclllllccccccccccccccccccccllllllllllccccccccccllllllllclccllllllllllllllllllllllccc:;;;;;;::::::c;,xK00000000000000000000000    //
//    oooooooooooooooooooc;col;;oool;':cccccc:;;;:ccccccccc:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::cloooooooooc'l000000000000000000000000    //
//    ooooooooooooooooooo:,ldc,:ooo:':lcccccccccccccccc;;;;;::::::cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccllloooooooooooooooooo;,x00000000000000000000000    //
//    oooooooooooooooooooc;ldc'cdoo:':lcccccccccccc:;;;:clooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo;;k0000000000000000000000    //
//    oooooooooooooooooooolool;;lool;,;:cclccllc:;;;:loooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooool,c0000000000000000000000    //
//    ooooooooooooooooooooooooo:,:looc;;;;;;;;;;;:oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo:,o000000000000000000000    //
//    ooooooooooooooooooooooooooc::cloooollcccclooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo:,d00000000000000000000    //
//    oooooooooooooooooooooooooooooloooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo,;O0000000000000000000    //
//    ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooollooooooooooooooooooooooooooooo:,o0000000000000000000    //
//    oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooolc::::loooooooooooooooooooooooooooooo;;k000000000000000000    //
//    oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooolcc:::::cloooooooooooooooooooooooooooooooooc'oK00000000000000000    //
//    ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooolccllooooooooooooooooooooooooooooooooooooooooooooooollcc:::::::::::looooooooooooooooooooooooooooooooooooool,cO00000000000000000    //
//    oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooool:;::::::::::::::::::::::::::::::::::::::::::::::::::::::cclloooooooooooooooooooooooooooooooooooooooooooooo:,x00000000000000000    //
//    oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooolllllcccccccccc::::::::::::::::::::ccccllooo                                                                              //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TPR is ERC721Creator {
    constructor() ERC721Creator("Trash Pepe Renaissance", "TPR") {}
}
