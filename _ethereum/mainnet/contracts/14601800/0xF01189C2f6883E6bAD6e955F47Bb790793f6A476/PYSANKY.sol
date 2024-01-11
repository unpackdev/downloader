
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pysanky For Ukraine
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                          //
//                                                                                                          //
//     , __                          _            ______                                                    //
//    /|/  \                        | |          (_) |                                                      //
//     |___/       ,   __,   _  _   | |             _|_  __   ,_                                            //
//     |    |   | / \_/  |  / |/ |  |/_) |   |     / | |/  \_/  |                                           //
//     |     \_/|/ \/ \_/|_/  |  |_/| \_/ \_/|/   (_/   \__/    |_/                                         //
//             /|                           /|                                                              //
//             \|                           \|                                                              //
//     _         _                                                                                          //
//    (_|    |  | |              o                                                                          //
//      |    |  | |   ,_    __,      _  _    _        ..                                                    //
//      |    |  |/_) /  |  /  |  |  / |/ |  |/     .';oo;'.                                                 //
//       \__/\_/| \_/   |_/\_/|_/|_/  |  |_/|__/     .:;.                                                   //
//                                   .             .';oo;'.             ..                                  //
//                                  ,xc.             .c:.             .lx'                                  //
//                                  'OKd,          .';oo;'.          ;xKk.                                  //
//                                  .kOdko'        . 'cc.          'dkdOx.                                  //
//                  .  'o;          .dOookkl.      .';oo;'.      .lkxooOo           :o'  .                  //
//                  .,,xWx.          o0ooodkk:.    ..'ll'..    .:kkoooo0l          .kWd',.                  //
//                 'oxk0O, :kc       c0doooodkd,   .';ll;..   ,xkdooood0:      .ck; ,O0kxl'                 //
//                 ;xxl,',;ONl  .    :0doollooxko. ..,ll,.. 'okxoolloox0;    . .oNk;,',lxx;                 //
//                    .:dxkko..dKc   ;Oxloc;coookkc..;ll;..lkxooo:;colkO,   cKo..okkkd:.                    //
//                    .lxo,.',l0k'.'.,kkloc..,coodkklcllclOkdooc,..colkk'.' ,O0c,'.,odc.                    //
//                        'dkkxo;.cNk;xOloc.  .;loodkkxxkkdool;. .'looOd;OXc.;oxOkd'                        //
//                        'oo;.':ck0;.dOool'   .':look00kool:.    ,looOo.:0kcc'.:ol'                        //
//                           .oK0dc:'.oOool,.    .,cldkkdlc'.    .,loo0l.':lxKKl.                           //
//          'lxdlllllccc::;;;:oxo;.':ck0doo;.      .,okko,.      .;old0x::'.;oxo;;;;::cccllllldxl.          //
//           .:xOkxxxxxxkkkkkkkkkkxxxk0Oxoo;.        ,ll,        .:oox00kxxxkkkkkkkkkkxxxxxdkOx:.           //
//              ;dkxoooooollooooooooooodxkxc.        .:;.        .cxkxdooooooooooollooooooxko,              //
//                'lkkdoool:,'',,,,;;;;;::ll;.   ..  .;;.  ..   .;ll::;;;;;,,,,'',:looodkkl'                //
//                  .cxkdool:,.            .,;'   .  .;,.  .   ';'.           ..,cooodkxc.                  //
//                    .;dkxoooc;.             ';'    .;,.    ','             .;coooxkd;.                    //
//                       ,okkdool;..           .';'..'::,..';'     .      .':loodkkl'                       //
//     ..  ..  ..  ..  ..  ,dkkdool:'.           .;c;,::;;c;.           .,:loodkkd'  ..  ..  ..  ..  ..     //
//    ,o;.'l:..lc..cl..:l'.;lcd0Oxdddl:'.........,;;:oxxo:::,.........':odddxOOocl;.,l:.'lc..lc..cl'.:o'    //
//    ,o;.'l:..lc..cl'.:l'.:l:o00xdddo:,'........,:;:dkkd:;:;........',codxxx0Ol:o;.,o:.'lc.'ll'.cl'.:o'    //
//     ..  ..  ..  ..  ..  'oxkxoolc,.           .;:;;:;;;c;.           .,clooxkxo'  ..  ..  ..  ..  ..     //
//                       .lkkdool:'.       .    ','..,::,..',.    ..      .':loodkxc.                       //
//                     ,okkoooc;..            ','  . .;,.   .',.            .';loodkko,                     //
//                  .:dkxoooc,..           .';'   .  .;,.      ';'            ..;coooxkd;.                  //
//                .cxkdoool:,''''',,,,;;;:ll;.   ..  .;;.  ..   .;lc;;;;,,,,''''',:looodkxc.                //
//              ,okkdooooollllloooooooooxkxc.        .;;.        .cxkxooooooooolllllooooodkkl'              //
//           .;dkkddddxxxxxxxkkkkkkkxkOOxoo:.        ,lc'        .:ookOOkxkkkkkkkxxxxxxxddddkkd;            //
//          'lkxoollllllcc::::oxo;',clk0doo;.      .,okkl'.      .;ood0klc,';oxo:::cccllllloooxxl.          //
//                           .oXKd:;'.o0ool,.    .':ldkkdl:'.    .;ooo0l.';:dKXo.                           //
//                        .cc,.,llkO,.dOlol'    .:loox00xool;.    ,looOo.;Oklc'.,cc.                        //
//                        ,k0Odl,.lWk;xOloc.  .;loodkOkkkkdooc,. .'looOd;ONc.;ldO0x'                        //
//                    .col'.,;l0x'.,',kkloc..,coodkOlcll:oOkoooc,.'colkk,',.'k0l;,.'lo:.                    //
//                    .lxOkxl..xXc   ;Oxloc,:oooxkl'.:ol;.'okxool:,colkO,   lXd..lxkkxc.                    //
//                 ,odc'',;OXc ..    :0doolloodkd' ..,lc'.. ,dkdoolloox0;   ..  lXk;,''cdo,                 //
//                 ,dkOOk' cOl       c0doooodkx;   .':ol;'.   :kkdooood0:      .lO: ,kOkxd,                 //
//                  .,,xWx.          o0ooookkc.      'c:.      .lkxoooo0l          .kWx,,.                  //
//                  .  ,d:          .dOooxko.      .':oo;'.      'okxooOo          .cd' ..                  //
//                                  .kOdkd,          .c:.          ,xkdOx.                                  //
//                                  'OKx:          .':oo;'.         .:xKk.                                  //
//                                  ,kl.             .:;.             .ok'                                  //
//                                  ..             .':oo;'.             ..                                  //
//                                                   .:;.                                                   //
//                                                 .':ol;'.                                                 //
//                                                   ...                                                    //
//                                                                                                          //
//                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PYSANKY is ERC721Creator {
    constructor() ERC721Creator("Pysanky For Ukraine", "PYSANKY") {}
}
