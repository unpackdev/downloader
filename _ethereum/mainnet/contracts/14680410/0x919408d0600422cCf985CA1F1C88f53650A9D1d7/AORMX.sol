
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Griffter - All Out (The Remixes)
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                   .,;;;;;;;;;;;;,,,,;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;,,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;,.                   //
//                   cXWNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNWXc                   //
//                   lNNd,,,,,,,,,,'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',,,,,,,,,,xWNl                   //
//                   lNX:                        .... .'. .. ... ....  '.  ... .'.                         cNNl                   //
//                   lNX:                        .cc'.,c;..'.,,. ':;.  ,, .:l'.'c:.                        cNNl                   //
//                   lNX:                         ...  .          .        ... ...                         cNNl                   //
//                   lNXc                                                                                  cNNl                   //
//                   lNXc                  ....',;;,',,',:::::::ccccc:::::;,,''.........                   cNNl.         .....    //
//                  .lNXc                  .;;;:cooolllcokOOOkOO0000OOOOOkdccc::::;,'.'.                   cNNl.      ........    //
//                  .lNXc                  .,;:c:;cooolld000000KKKK0kxkOkxo::;;;::c;'...                   lNNl.   ...........    //
//                  .lNXc                  .';;:;,cdooolxKKKK0KXXK0klclxkxo:::;;::c:'...                   lNNl.   ...........    //
//                  .lNXc.                  .;;:;;ldooookKK00O0KKOxdc::ldxocc:,;::c:,...                   lNNl.   ...........    //
//                 ..oNXc..                .';::::ldooookK0OxdxkOkddl;cdxxocc:,;::cc,.'.                   lNNl.   ...........    //
//               ....oNXl.....             .';::;;looolok00kxdxxxxxo:;cdxkdcc:,,:clc,.'.                  .lNNl.     .........    //
//                ...oNNl......            .';::;:looolokOkxollxOkkdlclloolclc,,:clc;''.                  .lNNl      .....',;:    //
//                  .oNXl...               .':::;coooolokOkd::cdkkkkxdol::lolc,,:clc;''.          ....... .lNNl      ';:cloddx    //
//                 ..oNXc..      ......    .,:c::cooolclxkxlccdxodxkOkdlcclolc;,:cll;''.           ......  cNNl      ':cclc:;:    //
//                 ..oNXl'..      .....    .,cc::loooc:lxdlldxOkddxkOOxololool;,:cll:''..  ...     ....'.. cNNl     .,;''.....    //
//                ..'dNNo,'.      ....     .,cc::lollc:oxdoxO00kdxOkkkxoloxkxd:;:cll;''..  ...     ':;,,'. cNNl     .',.......    //
//                .,oOWNxc,.    .:dkl,.  .cxollccllokOddkxkO0OOxdk0OOO00O0KXX0o;lkOdc,';ol',ldxxxxxkx;...  cNNl     ..'.......    //
//                .':kWNxc,.    :KNXKo.  .kNOdlccccdXN0kxdxOkxdodkO00KNNOkkxkK0llONOl:;:xKdcoocxX0ooc....  cNNl     .,;'......    //
//                ...dNNo,'.   .kXdl00:  .oXkllcc:co0NOdoodxkxooxO00O0NXkdoldKXocOXxc:;:kKo;;'.;00;,;'.... cNNl      ';;;;;:::    //
//                ...dWNo,'.  .dNNOldKk' .oNOoool::o0NOoloxkOOxx00OOk0NKkxocdXKl:kNx:;;cOKl'.. ,00;';,,,'. cNNl      .;;,,;;;;    //
//                .';xWNd;,. .:0OooxoxKx'.c0K0K00kolkKK0O0XK000KK0OOkOKXXK0O0Kx:;d00Okk0Kd,'.  'kKo''....  cNNl     .,,'......    //
//                .;o0WNkc,. .',...,;::'. .;lodddoc:loxxdk0Oxk0KKK00OkkO00kolc;,,;:loool,....   .,'',..... cNNl      .'.......    //
//                .';xWNd;,.      ....     .',,,,,,;::cc:okxdk0KKXKKOkxxxxl;',,,',,,:::,.  ..      .::::,. cNNl     .','......    //
//                ...dWNo..         .':lc,.;c;clclodl:clcx0000KXXNNX0O0Okkkocl:cllolldxd;.,c:;.    .';cl:. cNNl     .,;''''''.    //
//                 ..oNNc..          .,xl.'dOdOOodOkdcoooOKXNXXXNNNX00XXKKXkxxccOKkclx0kc'lxdl'        ..  lNNl      .:cloooll    //
//                  .lNXc.        .....l:..oxldxox0Oxdxkk00OKXKXNNNX00K00kkxddcoxxxolkKOo,;odo,    .','..  cNNl      ..';clodx    //
//                  .lNXc.        .,;'... .';,;:::cccok00000KKXXXXKKOkkkxol:;;;:;;:lclol'..''.     .',;:,. cNNl          .....    //
//                  .oNNl..       .,'.    ..,,;:c::cldk00000KKKKKK0OOkxxxdl::::;;;;clll:.  ...     ....... cNNl.      ...         //
//                 ..oNNd,.       .''.    ..',;clllodkO0000000KKKK00Oxxxxdolclc:;;;clloc.  .,'.    ......  cNNl      ..,'.....    //
//                .';kNNx;.      .';;'    ..,;:cllodxxxxkkkOOO0KXKKK0OOkdllc:cccccclodxl.  .'..    ......  cNNl      .';;:::;;    //
//                .,:kNNo'.      .';,.     .;cclodxxxxxxxkkOOOO0KK000OOxl;;;;:cclooddxko.  ...     ....... cNNl      ......,;;    //
//                 .'dNNl..      ..'..     .cddddxxxxkkkkO000000OkxkkxxdoodoodxxkkkkkkOd.   .       .....  cNNl      ...  ....    //
//                 ..oNNo..       ...      .cddddddxxxxxkkkkkOkdoooddodxxxxdddxkkkxxxkko.           .....  cNNl      ...          //
//                 ..dNNd'.                .cddddddxxxxxxxxxxdlloddxdlldxkkxxxxkkxxxxxkl.           .....  cNNl      .....        //
//                ..,xNNo'.                .;ccllllooooollloolclddddo:;codddddddddddddxl.           ...... cNNl      .........    //
//                ..,xNNl..                 ............................................             ..... cNNl      .........    //
//                ..'dWNl.              ..  ..   .  ...     .  ..   .   ..  ..     ..    ..            ..  cNNl      .........    //
//                 ..oNXc.              ,:..;c. ,c' .;'    .;,';:'.':c;.;c..:c.   'c:.  ,oo,               cNNl       ........    //
//                  .oNXc               .. .',.....  ..    .'...'. ..'..',. .,.   .,..  .,;.               cNNl      .........    //
//                  .oNXc.                                                                                 lNNl      .........    //
//                  .lNW0xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxKWNl       ........    //
//                   ;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd,       ........    //
//                                                                                                                    ........    //
//                                                                                                                     .......    //
//                                                                                                                      ......    //
//                                                                                                                        ....    //
//                                                                                                                          ..    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AORMX is ERC721Creator {
    constructor() ERC721Creator("Griffter - All Out (The Remixes)", "AORMX") {}
}
