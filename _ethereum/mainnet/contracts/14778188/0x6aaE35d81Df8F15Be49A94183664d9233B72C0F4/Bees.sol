
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bees Knees
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                        .,.                                                  .;,                                     //
//                                       .cOO:.                                              .;xKd'                                    //
//                                        ..,ll'                                            ,do;...                                    //
//                                            ckc.  ..',;;;,..                ......      .lk:                                         //
//          .;cccc:::;,.                      lNNo .,:::::;;:col;.        .;lc:;;;;cl'   ,xNX:                                         //
//         :xoc;;:;,:lollcc::,..              oWMXl.        .'l0NKdlcdxolx00o'         .lNMMK,                 .';;;;:c:;;;;:'         //
//         cc.        ..',,;:lllll:'.         ,KMM0,      .:OXNNWMMMMMMMMMWXK0k:.      cXMMXo.           .';::cccc;;,,;;,'..;o'        //
//         .l;.      .,,.''...  .;ldddl;.     .lXMWd.     ,0MWWWWMMMMMMMMMMNXXX0,     .xMMWd.       ..;cccclc:;,''.'''...   .l,        //
//          .oc..',..,:;,,'':;,,,'...;odxdl;.   ;kNNx,.   .OMMMMWNXKKKKXXNWMMWNd.   .:dKNOc.    .':ldkl,..:l;,..           ,l,         //
//           .;l,.....'''. .,:'.',,''cc..;okOkl;..oNWNKx:..oKKko:,,'.''..,:dO00d' .oKWMWx. .,:clll:,:c,,,';;:l;'.        .:o,          //
//             .:l'    .. ....,,..  .,c'   .,lk0KOk0NMMMWXxlc;..  .        .;:;lxdOWN0xdooxkdl:....,:. ...',;''''.      .cc.           //
//               'c:.      ..''',::;;;:ll,..',',cokO0XWWMW0l:.               ';,;OWNKOOOOxl,..  ..cxl'''::'''''..     .;c,             //
//                .;l:..     ..,,ll''..,d:..''''',,,;:lkKO0Nx. .              cOOXMWXOdol:,,,;:cclxc..  'c'..        'c;.              //
//                  .,::;,'',,,;cxko;..,dl,,;,,;;,;::cxKX00NKc.              .kNkok0kollc;;,,,;;,,l;  .,oxc.    ..,;c:.                //
//                     ..,:::::;;,;;::::ccccllldxkO0OO0KXOoOXo..             ,KNOxk0kdddlc::;'';:;od:cl:'.,;:::::::,.                  //
//                                  ..,coxOKXOollloollccoxk0kc'..... ...     .:dXNOxxxxxxkOkxkKK00Odl:'.                               //
//                              .;;;;,,;:lol;...''''..,oOXXx;,;,'..   .... ...'lOOkdc:;,'',...:o;.''',,;;;.                            //
//                            .cc;'.. ..',ll;,'''.  .'od;'lkxd:.''... ...'...ckk;..:ll;,;;,',:ldc.....  ..::.                          //
//                            'l' ...  .,;;,.   ..  'l;    .xXOc,lkkkkO00d;cxKx.    .coc;,'..;loc:;'..   ..oc                          //
//                             ,lc;'...;:'...,;:,,;::.    .:0WMNOOXWWMWWWNNNNWK:      'lo;....,;,.  .   .':c'                          //
//                              .;:;;;;;cx0KKKd:,'..     'lxOOKNNNNWWNXKK0kxoooo;....   .;:::;;:;,,;;;,,,,.                            //
//                                      lXMMWk.     .lkOO0c.  .'.',;;,....     ,k0XN0:     .:0WNNXd;'.                                 //
//                                      cXX0d.    .:OWMMMO;.                 .,xWMMMWXxc,.   ;ONW0,                                    //
//                                     'lc..   .cOXWWKk0WNKKkolc;,;ccc:coxxxOKXWMMNKxkNMWk'   ..lx;                                    //
//                                  .cxx,     .xWMMMNc.lNMMMMNkdd0WMMMWWMMMMMMMMMW0,.dWMMWx.     ;dc.                                  //
//                                 .:oOd.     :XMMMMK, lKXWMWO' .dWMMMMWWWWNNNXKxdl..dWMMMWx'    .xOo'                                 //
//                                    ..      ,0MMMWk. cKXNXOo,,,c0NNNNK00KXXNXXKXk. :0NMMMNo.   .:.                                   //
//                                           .:0WMXd.  ;XMWNX0c.'l0XXNWWNNWMMMMMMMk.  .;OWMK;                                          //
//                                          .xNMMWO'   .oXNNWXc. :XMMMMMMMMMWWNK0O:     oNMW0l.                                        //
//                                         .oNMMMMWo     c00xc::;ck0K0kxxxxkkkkkOo.    cXMMMMWk.                                       //
//                                         .OMMMMMNo.    ;KMWKOl.'kXNXXKKKXXNWMMNl     cNMMMMMK;                                       //
//                                         ;XMMMMNo.      cKWMMk.'kWMMMMMMMMWNKOc.     .kWMMMMO.                                       //
//                                         .lKMWNx.        .lOKkc;:oxk0KKK0OOkd'        ;KMMMNd.                                       //
//                                           cKk;.           ;ONXl,dKXXNNNWWNO:          lNMMk.                                        //
//                                           .do.             .;dkkKWMMMMN0d;.           .oX0:                                         //
//                                            cXOo;.             .:dkkkxc'.              .ox.                                          //
//                                            o0olc.                                    ,dOk'                                          //
//                                            ..                                       .;,'l;                                          //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Bees is ERC721Creator {
    constructor() ERC721Creator("Bees Knees", "Bees") {}
}
