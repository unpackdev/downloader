
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ONe Rad Latina
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//               WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNXK0OOkkkkkkOO0XNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNXKOxdoollcccc:cccloxOKNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNKOdc;,,,,,,,,,,,,,,,,;:cokKNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNKxc,.................''',;:ldOXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXkc,.........  ..........',;:lodkXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXx:''';lddo;...     .....',;:cloddOXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXx:',:x0NNXx:....      ...';:clodddx0NWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNO:,,lONNNXkc'.......    ..';clodxxxxkKWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWKo,,lONNNXkc'.........   ...;lddxxxxxx0NWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNO:,cxKXXKx:'............  ..'lxxxxxxxxOXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNx;;ok00ko;..............  ...:xkxxxxxxOXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXd;cdxdo:,................ ...;xOkxxxxxkXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXx:lxoc;'................. ...,dOkxxxdxOXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNk:ldl;'.................  ...,dK0kxxxxOXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWN0lldl;'.................  ...;xKKOkxxx0NWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXdldl;'......................:xkkkxxxk0NWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNOooo:'.....................,cddooodxkKWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXkooc,....................';loc::codkXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXkdo:'...................,;:;,,,:loONWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXkdl;'................','''..',;:o0NWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXkdl;...............','.....',,:dXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXOdl;............';,.....',:llo0NWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWN0xl;'........';;,....,;codxxkKWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNXOxl;,'',;::;,....,:ccc::cdx0NWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNKOkdolc:;'......',,,''',cdxkKWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXOxoc;'................,lk0kxkXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNKkxo:'................,lxOkdodkKNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNXK0Okxxo;'.............',:c:;;;;cldOXNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNX0Okkkkxolc:,.....................',;;coOKXNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNX0kxxkkxxdl:;'........................'';:ldxxxk0XNWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNKkkkkkxdolc:,'.......................',;;;,,,,;:cdOKNWWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNKKKXNNKOkkxdolc:;,'.....................',,,'.......'',;:oOXWWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWN0kkkOKNN0xdolc:;,,'...................,;;,'.............',:oONWWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNKxooooxKNXxlc:;;,''................,:cc:,.................,cox0NWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNOl::cldkXN0oc;;,''.............,:oxxo;'...................,lxkOXWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNkc;:codxONXkc;,''.........'',cdO0kl,......................,okkkKWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXx:;:lodox0N0o;,''.......':oxOK0d:'........................,oOOk0NWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    NNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWXd::coddolxXXx:,''....',:d0XKOo:,'.............   .........;dOOx0NWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    NNNNNNNNNNNNNNNWWWWWWWWWWWWWWWWWXd:coddol:lONOc,'...',cx0KOocc::,.............     .......';dOkx0NWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    NNNNNNNNNNNNNNNNNNWNNNNNNNNNWWWWXxodddoc:;;dXKo;''',:d0KOoclool:'.............     .......':xOkx0NWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNWNNKkddol:;'',c0Xx;,,;lOX0dlodddoc,...............     ......':xOxxKWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNWNNNNKkdoc:,'...';kXkc;:dKKxlldxxdol;'...........',..     ......'ckOxkXWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKxl:,'.......,dXOlckK0o:ldddolc;'...........';;..     ......,lkOxOXWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNXkc,'.........,oK0dkKOc,,;::;,...............,;'..     ......;okkx0NWWWWWWWWWWWWWWWWWWWWWWW                                                           //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNXx:'..........'l0K0XOc'....................';:;...     ......;dOkxKNWWWWWWWWWWWWWWWWWWWWNNN                                                           //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNXkc,..........'c0XX0l'....................':ddc'.      .....':dkxkKWWWWWWWWWNNNNNNNNWWWNNNN                                                           //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKx:'..........:OX0d,.....................'cxo;..      .....':xkxkXWWWWWWWWWWWWWNNNNNNNNNNN                                                           //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKxc,.........;x0x:'.......         .....';:,...      .....'cxkxONNNNNNNNNNNNWWNNNNNNNNNNN                                                           //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN0o:'........'okl,.....              .........      ......,cxkx0NNNNNNNNNNNNNNNNNNNNNNNNN                                                           //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN0l:;'........cxl,....             .......................,lxxx0NNNNNNNNNNNNNNNNNNNNNNNNN                                                           //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNOc;:;'.......:xo,.....           .............,ol........,lxxxKNNNNNNNNNNNNNNNNNNNNNNNNN                                                           //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNOc;::'.......:kx,.......       ......'.......;xKd'.......,lxxkKNNNNNNNNNNNNNNNNNNNNNNNNN                                                           //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNO:,::'.......:Ox,..................,;,......;xXXo'.......,lxxkXNNNNNNNNNNNNNNNNNNNNNNNNN                                                           //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNk;,::'.......:Ox,.................'::'.....,dXNXo'.......,lxxkXNNNNNNNNNNNNNNNNXXXXXXXXN                                                           //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXx;,;;'.......:Ox,.................,c:'....'lKNNKl........,lxdkXNNNNNNNNNNNNNNNXXXXXXXXXX                                                           //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXd,,;;'.......:Od'.................,::.....,xXNNKl........,lddkXNNNNNNNNNNNNNNNXXXXXXXXXX                                                           //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ONe1 is ERC721Creator {
    constructor() ERC721Creator("ONe Rad Latina", "ONe1") {}
}
