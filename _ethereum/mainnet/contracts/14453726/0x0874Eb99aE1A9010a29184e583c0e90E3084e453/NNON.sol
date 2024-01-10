
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NNON
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    KKK0000KKKKKKKKKKKKKKKKKKKKKKKKKKKKXXXXXXXKXXKKKKKKKXXXKKKKKKKXXXXXXXXXKKKKKKXKKKKKKKXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXKKKKKKXKXKKXXXXXXXXXXKKXXXXXXXXX    //
//    KKK00K0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXKKKXXKXXXKXXXXXXXXKXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXXXXXXXXXKXXXXXXXXXXXX    //
//    0KKK0000KK0KKKKKKKKKKKKKKKKKKKKKKKKKKXXXXXXXXXXXXXXKXXXKXKXXXXXXXKXXXKKKKKKKKKKKKKKKKKKKKKKKKKXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    00KKK000KKKKKKKKKKKKKKKKKKKKKKXXXKKXXXXXXXXXXXKXXKXXKXXXKKKKK0Okxollc:;;,,,,,;;;:clodxk0KKKKKKKXKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    K0000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXXXKKKKKKXKKKKKKOxoc;,...                           ..,;codO0KKKKKKKKKKKKKKKKKKKKKKKKKKKKXKKKKXXXXXXXXXXXXXKXXXXXX    //
//    K0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXKKKKKXXKXKKOd:'.                                            ..;lx0KKKKKKKKKKKKKKKKKKKKKKKKKKKKXXXXXXXXXXXKXXXKXXXX    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXKKKKKKXKKOd:.                                                      .,lkKKKKKKKKKKKKKKKKKKKKKKKKKKXXXXXKXXKKKXXXXXXXX    //
//    0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXKKKKxc'                                                              .:xKKKKKKKKKKKKKKKKKKKKKKKKXKXXKKKKXKKXXXKKXX    //
//    KKK00KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0o'                                                                    .cOKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXXKXXXXX    //
//    KK000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOc.                                                                        .,d0KKKKKKKKKKKKKKKKKKKKXKKKXXKKXXKKXXXX    //
//    00KK0KKKKKKKKKKKKKKKKKKKKKKKKKKKK0c.                                                                             .oKKKKKKKKXXXXKKKKKKXKKXXKKKKKKKKXXXX    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0o.                                                                                 ,kKKKKKKKXXKXXXKKKKKKXKKXKKKKKKKKKK    //
//    KK0000KKKKKKKKKKKKKKKKKKKKKKKKk,                                                                                     :OKKKKKXXKKKKKXKXXXKXXKKKKKKKXKXX    //
//    KKKKKKK0KKKKKKKKKKKKKKKKKKKKKc                                                                                        .oKKKXKKXKKXKKKXKXXXXXXXXKKXKKKX    //
//    KK0KKKKKKKKKKKKKKKKKKKKKKKK0:                                                                                           ,OKKKKKKKKKKKKXXKKKKKKKKKXKXXX    //
//    000KKKKKKKKKKKKKKKKKKKKKKKx.                                                                                             .o0KKKKKKKKKKKKXXXXKKXXKKKXXX    //
//    K0K00KKKKKKKKKKKKKKKKKKKKx.                                                                                                ;0KKKKKKKKKKKXKKKKKXKKXXKXX    //
//    KKK0KKKKK0KKKKKKKKKKKKKKx.                                                                                                  ,OKKKKKKKKKKXKKKKKKKKXXXKK    //
//    KK0KKKKKKKKKKKKKKKKKKKKd                                                                                                     .xKKKKKKKXXKKKKKXXXXXXXKX    //
//    KKKKKKKKKKKKKKKKKKKKKKO.                                                                                                      .0KKKKXKKXXKKXKKKKKKXXXX    //
//    KKKKKKKKKKKKKKKKKKKKKK;                                                                                                        :KKKKXXKKKXKKKKKKKKKKKX    //
//    KKKKKKKKKKKKKKKKKKKKKo                                                                                                          dKKXXKKXXKKKKXKKKXXXKX    //
//    KKKKKKKKKKKKKKKKKKKKO.                                                                                                          .0KXXKKXXKKXXXKKKKKXXX    //
//    KKKKKKKXKKXKKKKKKKKKo                                                                                                            dKXKKKXKXXXXXXXKKXXXX    //
//    KKKKKKKKKXXKKKKKKKKK,                                          .';codxkkOOOkxoc;.                                                cKKKKKKKKKKXXXKKKXXKX    //
//    KKKKKKKKKKKKKKKKKKKO.                                   .,codkOOOOOOOkOOOO0KKXXNN0xl'                                            ;KKKKKKKKKKXXXXXXKXXX    //
//    KKKKKKKKKKKKKKKKKKKl                                  :kKK00OkdolccllllodxxkxxkOKXNNN0l.                                         ,KKKKKKKKKKKXXKKKXXKK    //
//    KKKKKKKKKKKKKKKKK0O.    .,;;:::;;,..                '0XK0Oxol:;''',,:;;:lodkkkxdxOKXNNWNx.                                       'KKXKXKKKKKKXXXKKKXKX    //
//    KKKKKKKKKKKKKKKKKK:  .oKNNXK0Oxdddxkkdc.           .OXXOxo:,'......'',;cdxxxkxkkkkOKXNNWWK:                                      'KXKKKKKKKKXKXKXKKKKK    //
//    KKKKKKKKKKKKKKKKKO. .OWNNNK0kol:;;;cldkk,          :NXKOkdc;'...........',:dOK0kdkOKXXXNNWN:                                     'KKKKKKKKKKKKKXXXXKKX    //
//    KKKKKKKKKKKKKKKKKk. ,NNNNXKOxc;,....,coxc          cNXK0Oko:,.. ....       ..,;::lxO0KXXNWNx                                     ,KKKKKKKKKKKKXXXXKKXX    //
//    KKKKKKKKKKKKKKKKKK; .ONNXK0Oxc'......'co.          'XXK0OOd;.   .':c.     ..','..'cx0XNNNWWk                                     cXKKKKKKKKKKXKXKKKKKK    //
//    KKKKKKKKKKKKKKKKKKx. ;XXXXOo;.       'c,            ;0XK0koc;... . ........',clook0XXNNNWWNd                                     dKKKKXKXXXKKKKKKKKKXX    //
//    KKKKKKKKKKKKKKKKKKK:  dX0dcldc.    .,:.              .:OK0xoc;,,,;,,,,,;,',:coxOXNNNWWWWWWW:                                    '0KKXKKKKXXXKXXXXKKXXX    //
//    KKKKKKKKKKKKKKKKKKKo  :000OOxc:,';co;.                  ,d00OxolllllooodxkOKXNNNNNWWWWWWNWO.                                    xKKKKKXKKKKKKXKXXKXKKK    //
//    KKKKKKKKKKKKKKKKKKKl  cNNNNKkxxkOOl.                      .o00OOkkkxxkOOKKKXNNNNNNNNNNWWWX,                                    .kKKKKKKKKKXXKXKKKXKKKK    //
//    KKKKKKKKKKKKKKKKKK0,  kNWNNNNNNNd.                          .dKKKKK0KKKKXXXNNNNNNNNWWWWWNc                                      oKKKKKKKKKKKXXKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKo  :NWWWWWWWNl                              'kXXXKXXXKXXXNNNNNNWNWWNWNl                                       .OKKKKKKKKKKXXKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKk. .XNNWWWWWX:                                .c0XXXXXXXXXNNNNNNWWWNKo.                                         oKKKKKKKKKKKKKKXKKKKK    //
//    KKKKKKKKKKKKKKKKK:  'KWNWWWNO'                                   .dKXXXXXXXNNNNNNNKd,                                            cKKKKKKKKKXXKKKKKKKKK    //
//    KKKKKKKKKKKKKKKK0.   .,cooc'                                       .:dOKXXNNNNKOo,                                               cKKKKKKKKKKKKKKKKKKKK    //
//    000KKKKKKKKKKKKKk.                                                      ......                                                   lKKKKKKKKKKKKKKKKKKKK    //
//    KKK000KKKKKKKKKKk                                                                                                                xKKKKKKKKKKKKKKKKKKKX    //
//    KKKKKKKKKKKKKKKK0.                                                                                                              ,KKKKKKKKKKKKKKXKKKKKK    //
//    KKKKKKKKKKKKKKKKK;                                                                                                             .OKKKKKKKKKKKKKKKKKKKKK    //
//    0KKKKKKKKKKKKKKKKd                                                                                                            'k0KKKKKKKKKKKKKKKXXKKKK    //
//    KKKK0KKKKKKKKKKKK0:                                                                                                         .:OKKKKKKKKKKKKKKKKKKKKKKK    //
//    00000KKKKKKKKKKKKK0'                                                                                                       .dKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    00000KKKKKKKKKKKKKKo                                                                                                     'lOKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    0000000KKKKKKKKKKKKK,                                                                                                .:ok0KKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    0000000KKKKKKKKKKKKKx                                                                                              ;xKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    0000000KKKKKKKKKKKKKK:                                                                                           .dKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    0K0000KKKKKKKKKKKKKKKO.                                                                                         l0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    0K00KKKKKKKKKKKKKKKKKKc                                                                                       .xKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKK0KKKKKKKKK0.                                                                                      dKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    00KK000KKKKKKKKKKKKKKKKl                                                                                     ;KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00KKKK    //
//    K000000000KKKKKKKKKKKKK0'                                                                                    l0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KK00000KKKKKKKKKKKKKKKKKx.                                                                                   o00KKKKKKK0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    K00KKKKK0KKKKKKKKKKKKKKKKc                                                                                   l00KKKKKKK00KKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    000KKK00KKKKKKKKKKKKKKKKK0'                                                                                  ,00KK0KKKKKKKKK0KKKKKKKKKKKKKKKKKKKKKKKKK    //
//    K00KKKKK0KKKKKKKKKKKKKKKKKk.                                                                                  d0000KKKKKKKKKKKKKK0KKKKKKKKKK0KKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKO.                                                                                 .kK00000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKK0KKKKKKKKKKKKKKKKKKk'                                                                                 .oK00K0000KKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKO;                                                                                  ,k0K00KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKo.                                                                                 .cOKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    00KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk;                                                                                   'oOKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk,                                                                                   .,ok000KKKKKKKKKKKKKKKKKKKKKKKK    //
//    000KK0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKkc.                                                                                    .:ok0KKKKKKKKKKKKKKKKKKKKKK    //
//    0000K000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0o.                                                                                      .;lk0KK0KKKKKKKKKKKKKKK    //
//    KKK0K0K0KKKKKKKKKKKKKKKKKKKKKKKKKXKKKKKK0l.                                                                                        .;lx0K00KKKKKKKKKKK    //
//    K0000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0l.                                                                                          .,cdOKKKKKKKKKK    //
//    KK0K0K000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKl.                                                                                            .'cx0KKKKKK    //
//    K0KK00KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXKk,                                                                                               .,:oOKK    //
//    KK00000K0K0KKKKKKKKKKKKKKKKKKKKKKKKKKKXKKKKXXXXKx.                                                                                                  .;    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NNON is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
