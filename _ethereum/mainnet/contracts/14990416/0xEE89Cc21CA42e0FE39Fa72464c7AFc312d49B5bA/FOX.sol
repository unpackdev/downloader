
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Foxy Girls
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                              .             //
//                                                                                       .';ldkkdlc.          //
//            .,:ccccccc:;;'...                                                      .;okKNWWKx:..cl.         //
//           :dc:codk0XNNNNNXKOkdl:,..     .loloxo'    .....'''....               .:dOKXNNN0l.    ;o.         //
//           ox.     .,cd0XWWMWWWWNXK0kxdl:oXMMWMMXxllllllloooooooooolc;.      .;oxdlcloxxc.      ;d.         //
//           ck'         .,lkKNNNXNWMMMMMMWWMMMMMMMNl.            ..';coddo:'.,ol,.  ..:c'        :d.         //
//           ;0l             .;ok0NMMMMMMMMMMMMMMMMNc                    .;coxOo.    .,;....      ld.         //
//           .k0,               .lXMMMMMMMMMMMMMMMMO'                        .;loc.  .'...',;,.  .dl          //
//            :Kd.               ;KMMMMMMMMMMMMMMMNo....                        .;ll:;.    ':lc' 'x;          //
//            .xKc      .,:;:llclOWMMMMMMMMMMMMMMW0l,..                            'll'    .;c;. :x.          //
//             ,00,    ,xl,:xKNWMMMMMMMMMMMMMMN0o;.                                  .::.    .:,.oc           //
//              cXx.   ld,lKWMMMMMMMMMMMMMMWKd;.                                       ,:'  ''..,o'           //
//              .dXl   .,:xKKNMMMMMMMMMMMWOc.                                           .,' ..  c:            //
//               .x0;     .oKWMMMMMMMMMW0:.                                               '..  ,l.            //
//                .xO,    .xNNNWMMMMMMNd.                                                  .. .c,             //
//                 .dk'    .;cOWMMMMWKc.                                                    ';l:              //
//                  .co'     .dXWMMNx'                                                      .:;               //
//                    ;d:   .,;kWMXl.                                ..                      ',               //
//                     ;xo,,,.'OWK:             ..                  .'           ...         .;.              //
//                      .oo,  'OO,              ''         ...   . .,.          .;. .        .c.              //
//                      ';.   .'.              .;.        ...  ...',...        .c,  ..    .  ,l.              //
//                     ;c.              .     .;.     .....  ....'....   ... .,c,   .'.  ..  :l.              //
//                   .cc.               ..   .'.     ...   .......... .,;'..':;.     ;;  .. .o:               //
//                  .lc.               .;,':oxolllolc:;,'.....  ....,;:,...,'.       ,c..,. :d.               //
//                 .lc.                ,::l:,''',;;:ccloool:'.':c:::;.....,;;::::::;':o;;. 'o;                //
//                 cl.          ''    ':'....;coooc,.    ..',,'....      .',,'...'',,lko' .c:.                //
//                ,o.          ,c;,'.,dkdodOXWMMMMN0Od'              .    .,;;,.     ;o'  '.                  //
//                cc           ,,  .'''ckxkNMMMMMMO,,okc..          .  .;xKNNkcoo:..,l' ...                   //
//               .o,           ';.        ;KMMMMXx,   .''.         ..  :XMMMX:  c0xcl,   .'                   //
//               ,c.           ..,.        lXMMM0,                 ..  :XMNk;.   ..;:.   .:'                  //
//               ::          ..  .,.        ,d00d'                     .dXKl.     .:'     ::                  //
//              .c,         .,.   .,..        ...                        .'.      ';      .c.                 //
//              .l,         ,'   .....''       .                     .           .;'       ;:                 //
//              .l,        ';.   .'... ,'                           ...     .    ';.       .c,                //
//               c;        ,'    ''.'   ',                         ...          .:'         :c                //
//               ,c.      .'.    ''''   .,,.                                   .c:  .       ;l.               //
//               .l;      .'.    .'''.  .....                                 .;,.  ..      ;c.               //
//                'l'      ..    ..'......  .;,.              ...           ';,.    ..      ;;                //
//                 .c,     ..     .'. ....    ;oc.                       .,;,.             .:.                //
//                  .,,.    ..     ..  .''.  .cl:;;,.                 .',,.               .;'                 //
//                     ..    ..     .   ..'';:,.. .':c;..         ..,,,..                .;'                  //
//                             ..     .    .,.  ..   .,:c:;'..',''''..  ..'.....   .    .'.                   //
//                               .....'.....'.   .'.      .'.,cc,     ..';:;,''..... ....                     //
//                                 ..',cc'   .'.   ...      .'.....        .......                            //
//                               ..';'  .;,.  .,.    .    .... .',::'..                                       //
//                             .;.  .;;   ,:.   .''.  .. .,.  .,. .:;'''''.                                   //
//                            ,;.    .::.  ':'    .'...   .,''.    .:'  ..;c'                                 //
//                          .;,       .:c.  ';.             .       ':'    ,l.                                //
//                         .;'          ::. .''.                    .,,.    ':'                               //
//                         '.           .:'  ...                     .'.     ,l.                              //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FOX is ERC721Creator {
    constructor() ERC721Creator("Foxy Girls", "FOX") {}
}
