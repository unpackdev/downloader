
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alexis at Manifold
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//       __    __    ____  _  _  ____  ___  ..............',,''''''......'',;::ccclllloooddxkkOO00KXNWMMMM    //
//      /__\  (  )  ( ___)( \/ )(_  _)/ __) loodddxxkkkOOO000000OOOkkxddolllccc::cllclcccc:;,,,;;;,;cccccc    //
//     /(__)\  )(__  )__)  )  (  _)(_ \__ \ NXXXXXXXKKKKKKKK0000000KXXXNNNNWMMMMMMMMMMMMMMMMWWNNNNXKKK00OO    //
//    (__)(__)(____)(____)(_/\_)(____)(___/ XKKKXXXKKXXK0000000OO0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    ,cxKWMMMMWNNWN0kkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX00000K000KXNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    NWWWNNXX0kxxOOl:lkNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN000KKK00000000KXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    xxxO0kxo:,,:::lxkkOO0XWMMMMMMMMMMMMMMMMWNWNNNXNWNNNWMMWWWWWWWWNNWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//       .::'.       ..    .,:cldONMWMMMMMWNX0000KXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNXNWWWMMMMMMMMMMM    //
//                                ',,;lkOOOO00KNNWWWWWNNNXXXXNNWWWMMMMMMMMMMMMMMMMMMMMWWWK0XWWWMMMMMMMMMMM    //
//                                       'xXXNXXKkooc:;''.....',;:cloodkOO0XNWWMMMMMMWNNWXXWWWMMMMMMMMMMMM    //
//                                     'lkKKK0O0k;                        ..ckKKXNWMMMMMWNWWNWMMMMMMMMMMMM    //
//                                  .ckXX0OO00OkOc                         .cxxkO0KXWMMMMMMMWWMMMWWWWNXKKK    //
//                                .lKWWK00OOd:'.,,'..                     .oK0O0XXK0KWMMMMMMMMW0ooolc;'...    //
//                               ,OWMWX0O0Oc. .cdkkxdxkddl.               lNNNXK0KXXXNMMWX0xocc.              //
//                             .oNMMMX0OO0d''odl,.  .,dKNXl              'kKX0Oo:dOKXXWNd.                    //
//                            .xWMMMN0OO0Olcdoc'....,lxOO0kl,.         .;kNWWWNXK0K0KXNN:                     //
//                           .dWMMMMX0OO0OkkodOkk0KXNWNXXK0OOl.       ;kXK0X0OXMMMWWWXKNc                     //
//                           :XMMMMMXOOOOOOO00KXXWMMMMMMMMX0o.       .dKx:cdookXMMMMMX0Nl                     //
//                          .OMMMMMMX0Oxk0000KWMMW0dx0XWWK0x.        .do';oc',lKMMMMMNKNl                     //
//                          cWMMMMMWXkl.'lold0WMWO;.l0XNXkdl.         ;c.';:;c0WMMMMXkO0;                     //
//                          oMMMMMMWXl       .;oddolloolc;.            :l.   .',:cdOl,x0;                     //
//                         .xMMMMMMWKo'                                 ..         ...ox'                     //
//                          ,lOWMMMW0kd;                                             ;Od.                     //
//                          cdo0NNWX0O0kl'                              .,.         ;k0d.                     //
//                        .:ck0OO000OOO0Oko;.                    .cdl:;ckx.        ;k0Kl                      //
//                        lk.;x:o000OOOOOOOOko;.                ..''.,oddc.       'dO00;                      //
//                        lXc'c'.lxdO0OOOOOOO00kc.                               'x0OXd.                      //
//                        :NXl'. 'dxxkOOOOOOOOOOOd.                             .d0OK0,                       //
//                        ,KMW0l'.:clxOOOOOOOOOO0O:                ....':c;.   'dO0OKo                        //
//                        .dWMMNOl. .cOOOOOOOOO0kc.            .;cdkOOO0K00kl';dO0O0O;                        //
//                         .cdk00c   .oXK0OOO0Okc           .;o0Kxl;;::lxKXXX0kdoO00d.                        //
//                            .:cc.  .kWWXOOOo'.           .cxOOd,''.',:oOKKK0d'.dOx;                   .;    //
//                            .ck0OllkKNMWK0k;               ..,;,',::;:ok00O0x,'dx:.                 .lxO    //
//                            .;oxkO00KWMWX0Odlc'              ..;;cc;;,,,,:ddxdlkk'                ;lk0OO    //
//                               ....,dKWMX00000Oo'.                        ..;dxOc             ..;lO0OOOO    //
//                                     ,xNX00OOOO0kc.                        'dOOl.           .:dO000OOOOO    //
//                                    .cxKX0OOOOOO00xool:;.                .:xOx;         ..;oO0OOOOOOOOOO    //
//                               .  ..;x0000OOOOOO00KKKKK0ko:'..         .'o0XO'       .;lxkO0OO0OOOOOOOOO    //
//                               . .dOO00OOOOOOOOOOOKWMWWWNXXK0Oxooooolok0XNWM0,   .':ok00OOOOOOOOOOOOOOOO    //
//                                 .x0OO0KK0OOOOOOOO0XNMMMMMMMWWWWWWNWWWMMMMWX0OOO0KNXKOO00OOOOOOOOOOOOOOO    //
//                                 .l0O0NWXOOOOO0OOkkO0KXXNWMMMMMMMMMMMMMMWX0O0XMMMMMMWXK0O0OOOOOOOOOOOOOO    //
//    :.                            'kNWMN0O0OOO0OOkkO0OOO0KXXNWMMMMMMWNNX00OOOKWMMMMMMMMN0kk0OOOOOOOOOOOO    //
//    0kdl;'..                     .oXMMMN0OOOOO0OOO00OOOOOOOO0KKXKKKK00OOOOOOO0KXWMMMMMMMWOdk0O00OO0OOOOO    //
//    X0O00Okxoc;'..             .:OWMMMMX0OOOOOOO0OkO0OOOOOOOOOOOOOOO0OOOOOOOOOO0KNWMMMMMMMNKOO00OOOOOOOO    //
//    WX000OOOO00Okxddo:;,''...;oKWMMMMMMX0OOOOOOO0kkkkO00OOOOOOOOOOOOx::k0OOOOO0OO0NMMMMMMMMMWX0OOO0OOOOO    //
//    MWNXK0OOOOOOOOKWMMMWWNXKXWMMMMMMMMMX0OOOOOOOOO0OkO0000OOOOOOO0Ol. ,x0OOO0kdddONMMMMMMMMMMMWXKOkO00OO    //
//    MMMMWNNXXXXXXXWMNKxd0MMMMMMMMMMMMMMN0OOOOOOOOOOO0OOOO0OOOOOOko,   :O0OO00OxxodNMMMMMMMMMMMMMMW0c:ldx    //
//    MMMMMMMMWNXKOdl:'. ;KMMMMMMMMMMMMMMXOkO0OOOOOOO00xcok0OOO0Od:'.  .o0O0OlcxOOoxWMMMMMMMMMMMMMMMWd.  .    //
//    X0kdol:;,'..      ;KMMMMMMMMMMMMMMMXOkOOOOO0O0OocllcokOOO0k::d'  'k0Ok:. .oxdKMMMMMMMMMMMMMMMMMX;       //
//    ..               '0MMMMMMMMMMMMMMMMXOOOOkxkOO0o. .;cc';kOl,..l,  'x0k;   .,,dWMMMMMMMMMMMMMMMMMMd       //
//                    .dWMMMMMMMMMMMMMMMMX0O0d,',;c:.       .ol    ..  .dl.   .cccKMMMMMMMMMMMMMMMMMMMO.      //
//                    cNMMMMMMMMMMMMMMMMMWXOo:. ...       .';:.    ..   ..    ..,kMMMMMMMMMMMMMMMMMMMMK,      //
//                   ,0MMMMMMMMMMMMMMMMMMWXkdx; ..       .oOk:                ''oWMMMMMMMMMMMMMMMMMMMMWl      //
//                  .kMMMMMMMMMMMMMMMMMMMMXx:;.     ..   .l0d.                 ;KMMMMMMMMMMMMMMMMMMMMMMO.     //
//                 .dWMWWWWNXXK0OKWMMMMMMMNd.       'c.   ckxc;::.             lWMMMMMMMMMMXkkOOOkkkkkOk;     //
//                  ';;,,,''...,l0WMMMMMMMXd;       ....'...cOOko.            ,0MMMMMMMMMMMXxc'.              //
//                         .'lkXWMMMMMMMMMNkxl'... .cool:.  .,;'.    ..     ..xWMMMMMMMMMMMMMMNOd:.           //
//                      .;o0NMMMMMMMMMMMMMWKO0OOkxook0Ol..         .;xxlccldxONMMMMMMMMMMMMMMMMMMWXOd;.       //
//                  .;lkXWMMMMMMMMMMMMMMMMMN0OOOOO00O0kdool;.     ;xO0O0000O0XMMMMMMMMMMMMMMMMMMMMMMK:        //
//                 .OMMMMMMMMMMMMMMMMMMMMMMWKOOO00OOOO00000Oxdo::ok0OOOOOOOOKWMMMMMMMMMMMMMMMMMMMMNx.         //
//                  ,OWMMMMMMMMMMMMMMMMMMMMMX0OOOOOOOOOOOOOOOO00000OOOOOO0OKNMMMMMMMMMMMMMMMMMMMMK:           //
//                   .oNMMMMMMMMMMMMMMMMMMMMN0O0OOOOOOOOOOOOOOOOOOOOOOOOOO0XMMMMMMMMMMMMMMMMMMMNx.            //
//                     :KMMMMMMMMMMMMMMMMMMMWXOOOOOOOOOOOOOOOOOOOOOOOOOOO0XWMMMMMMMMMMMMMMMMMMK:              //
//                      'OWMMMMMMMMMMMMMMMMMMN0OOOOOOOOOOOOOOOOOOOOOOOOOOKWMMMMMMMMMMMMMMMMMNx.               //
//                       .dNMMMMMMMMMMMMMMMMMWKOOOOOOOOOOOOOOOOOOOOOOOOOKWMMMMMMMMMMMMMMMMW0;                 //
//                         :KMMMMMMMMMMMMMMMMMN0O0OOOOOOkkkkOOOkkkkOOkO0NMMMMMMMMMMMMMMMMKl.                  //
//                          ;KMMMMMMMMMMMMMMMMWX0OO00O0Okxxxk0OkkddOkxONMMMMMMMMMMMMMMMMNl.                   //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ALEXIS is ERC721Creator {
    constructor() ERC721Creator("Alexis at Manifold", "ALEXIS") {}
}
