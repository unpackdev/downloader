
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tania Rivilis Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                       ................     ......  .........                                                                                                 //
//                      ;OXXXXXXXXXXXXXXKOxxk0KK0000000KKKKKK00OOOOkkxxddddddoc;coxkxxddddddddollccccccc:'.... .............''....:lc:;;,.                      //
//                     .dNWMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMMMMMMMMMMMMMMMMMMMMWNXXX00KKKXKK000KXNNNNNXXXWMMWWWWx.                     //
//                     ,KMMMMMMMWMMMMMMMMMMMMMMMWWWWMMMMWXNMMMMMMMMMMMMMMMMMMWWWMMMMMMMMMMMMWWWNWMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMWMMMMMMk.                     //
//                     ;KMMMMMMWXXXXKOOOxdddxk0KXXXXNNNXx:oOKNWMWMMMWNNWMMMWNXNWWWWWWWWWWWWWXKNWWWMMMMMMMMMMWNXWMMMMWXXWWMMMMMMMMWNWMMMMMk.                     //
//                     lNMMMMMM0;....          ....''.''...,;:cc:clcc:cllloolccc::;,;okkkkOOkkO0OOKXXK00OOOkxddxxk00Okxx0XKKNWWX0NMMMMMMMk.                     //
//                     cNMMMMMMk.                                                     .................   .       ..........;cccdXMMMMMMMk.                     //
//                     cNMMMMMMO.                                                                                               ,KMMMMMMMk.                     //
//                     :XMMMMMM0'                                                                                               ,0WMMMMMMx.                     //
//                     cNMMMMMM0'                                                                                               ,ONMMMMMWd.                     //
//                     oWMMMMMM0'                                                                                               ,KMMMMMMWd.                     //
//                     lXNMMMMM0'                                                                                               ,KMMMMMMWd.                     //
//                     :OXMMMMM0'            ,::::;;ccclcc:,,,;clloooddddddxdlclllllloolclkOkkkxxxddddo:,,,,;;,,c:.             ,0WMMMMMWo                      //
//                     .cKMMMMWk.           .kWMMMWWMMMMMMWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWXXNWWx.            ,OXWMMMMWd.                     //
//                      cXMMMMNc            .oXXNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'            .dXWMMMMWd.                     //
//                     .xWWMMMNc             oNWMMWWMMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMWWWMMMMMMMMMMMMMMMMWWWNWMWWWMMK;            .oNWMMMMX:                      //
//                     .xWWMMMNc             'llokKXXXNNK0O000000KKXXXXKKKXNWMMMMMMXl,;clllooddddoddddoc:c:;codOKNNl            .dWMMMMMX;                      //
//                     .dWMMMMNc                 .''.....................':kNMMMMMMK,                          ..d0:            .dWMMMMMK;                      //
//                     .dWMMMMNd.                                          :KMMMMMMNo.                           ..              ;KMMMMMNo.                     //
//                     .xMMMMMM0'                                          ,0MMMMMMMK;                                           'OMMMMMMk.                     //
//                     ;KMMMMMM0'              ...;ol,.   .........',,,,'.'dNMMMMMMMX:...                                       'dKMMMMMMk.                     //
//                     cNMMMMMM0'           ckkKKKNMMX0OOO0XXXXXXXXNWWWWNXNWMMMMMMMMWK0K00OOOOOOkkxdl:;;'...                    ;KWMMMMMMk.                     //
//                     cNMMMMMMK;          .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXK0kl.                 ;XMMMMMMMO.                     //
//                     cNMMMMMMNc           cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXXWMMMMMW0o,               ,0WMMMMMMO.                     //
//                     lNMMMMMMNc           :XMMMMMMMWWWWMMMMMMMWWWMWWWWMWNWMMMMMMMMMMMMMMMMWWWWMMN0kokWMMMMMMMMk.              .lNMMMMMMk.                     //
//                     lNWMMMMMNc           .lXMMMMMMKkdolccccccc:ccc:;:ccckNMMMMMMMW0xdodddxkkkOOxoloONNWMMMMMMK;              .xNMMMMMWo                      //
//                     lKXMMMMMNc            ,kO0XWWKc.                    :XMMMMMMMNo.            ...',:xNMMMMMWO'             'xKMMMMMWx.                     //
//                     lKNMMMMMNc             ...cxx;                      ,KMMMMMMMNc                   .dNWMMMMWx.            ;ONMMMMMMk.                     //
//                     ;KWMMMMMNc                                          .OMMMMMMMX:                    cKWMMMMMX;            cOKWMMMMMk.                     //
//                     .OMMMMMMWo                                          .OMMMMMMMK;                  'o0XMMMMMM0'            c0XWMMMMMk.                     //
//                     ,0MMMMMMWx.                                         .kMMMMMMMNkc:;;,....  ...,;ckXWMMMMMMMWd.            cNMMMMMMMO.                     //
//                     oWMMMMMMWx.                                         .OMMMMMMMMMWWWWNXKXKOk0KKNWWMMMMMMMMMNo.             :XMMMMMMMO.                     //
//                     oNWMMMMMWx.                                         ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;               ,KMMMMMMMk.                     //
//                     oWWMMMMMWd.                                         :XMMMMMMMMWWMMMMMMMMMMMMMMMWXK0kxkx:.                ,KMMMMMMWx.                     //
//                     lWMMMMMMWx.                                         cKNMMMMMMMNNWMMMMMMMMMN00K0xc;..                     .OMMMMMMWl                      //
//                     :XMMMMMMWd.                                         :0NMMMMMMWK0NMMMMMMMMMN0d;..                         .kMMMMMMNc                      //
//                     ;XMMMMMMNl                                          lKNWMMMMMXl:xKWMMMMMMMMMNOc.                         .kMMMMMMNc                      //
//                     ,0WMMMMMNc                                         .dXNWMMMMMO.  .l0NMMMMMMMMMWKl.                       .dWMMMMMNc                      //
//                     ;0WMMMMMNc                                         .xWMMMMMMMk.    .;xXMMMMMMMMMW0l.                      oWMMMMMK,                      //
//                     ;KWMMMMMNc                                         .xWMMMMMMMk.       'oKWMMMMMMMMWKo.                   .dWMMMMM0'                      //
//                     ;KWMMMMMNc                                          lNMMMMMMMk.         .l0NWWMMMMMMNd'                  .oXWMMMM0'                      //
//                     ;KMMMMMMNc                                         .xWMMMMMMMk.           .ckXMMMMMMMWXd'                .oKWMMMMK,                      //
//                     ,KMMMMMMNc                                         ;XMMMMMMMMk.             .,oONWMMMMMWXo.               lNWMMMMX:                      //
//                     ,KMMMMMMX:                                  .,,'',:dNMMMMMMMM0:..              .ckKNMMMWWWKl.             lNMMMMMWo                      //
//                     .xNMMMMMX:                                 ,ONWNNWWMMMMMMMMMMWNX0OOkxo'          .;kNWWWXKKXOd;          .OMMMMMMWo                      //
//                      cXWMMMMk.                                 .:xXNWWMMMMMMMMMMMMWMMMMWWX:           .oOk0XOoOWWNKl.        ,KMMMMMMWo                      //
//                      :XMMMMMk.                                   ,ONWWMMMMMMMMWWXxkWMMMWXk.            .'cdOKXWMMXk;.        ,KMMMMMMWo                      //
//                     .dWMMMMMO.                                   ,xO0XNNNWWNXXXXXkkNWNXXNd.                .'cd0Kc           ,KMMMMMMWo                      //
//                     .xWMMMMMO.                                   .,,,,'',;;;;::cc::clc,.'.                     ..    ,:.     '0MMMMMMWo.                     //
//                     .xWMMMMM0'                                                                                        .      '0WWMMMMWd.                     //
//                      ;0MMMMM0'                                                                                               ,0XOONMMWd.                     //
//                      '0MMMMMX:                                                                                               'kXXKNMMWd.                     //
//                      :XMMMMMWO:;;;;;;,,,,;;;;;,;;'....''''''',;;;;;;;;;;;;;;;;;;,,;:cccccccccccc:,.          ..,;:cccccccllclxXWMMMMMWd.                     //
//                     .kWMMMMMMWWWWWWWWWWWWWWWWWWWWNXXXNNNNNNNNWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMWWKkkkOOOO0000XWWMMMMMMMMMMMMMMMMMMMMWo                      //
//                     ,0WMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMWKc                      //
//                     ,0WWWMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMWWWMMMMMMMMMMMMMMMMMMMMMMMMMMWXXX0x0WMMMMMK;                       //
//                     'o::o0WMMNXNXXNWWWWWWWWWNXNNXXNNNNNNWWWWWWWNNWWWXXXXNNWNXKOO0KXXXNNWWXK0KKOdlllodddxkkkOOkkkxkO000KOdxO0O0XK0xll;.                       //
//                      .   ,kXXkc;;;;,,,,,,,,;,,;,..'''''',,,,,,,'',,,,,,,,,,'..  ......',,,'','.                   ................                           //
//                           ....                                                                                                                               //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TRA is ERC721Creator {
    constructor() ERC721Creator("Tania Rivilis Art", "TRA") {}
}
