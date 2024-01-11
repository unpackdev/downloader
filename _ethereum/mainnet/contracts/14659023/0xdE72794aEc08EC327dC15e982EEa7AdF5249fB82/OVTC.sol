
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Over the Clouds
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                     ....                                                    ....                               ........ ....                                ...                            //
//                  .',cdOK0d;                                            .   .dN0,                            .cdl'..:dOx.:XXl                               .xNO'                           //
//                .c:.   .cOWWk'                                         'o'   dM0'                           :KNd.     ,;.;XWc                               .xMO.                           //
//                l0,      .oNM0'.;c;.    ',. .,'.''.  'c:;,..,,.      .lK0:.  dMK;..',.     .,,'.''.        :XM0'         ;XWl   .'::;.   'c:.   .:c,   .,;'.'kMO.  .,'.''..                 //
//               .OX;        lNWl.oWX:    ;;:k0l..:00c.lWM0:..cKl      .xM0,   dMK:...dKo. .o0k,...dKx'     .kMMx.         ;XWl .c;':kNXx' cWN:   ;KMd..dKKc..'OMO..oXO,..lOk'                //
//               '0Wd.       .kMo .kMO.  .'cXWd   ;KMk.cWWl    ..      .xM0'   dM0'   ,KWl.xMK,   .xWNc     .kMMd          ;XWc.x0'   cXM0':NN:   ,KMo'kMWl   .xMO.,KMNx;. ';.                //
//               .dMNd.       oX;  ,KWd..'.dMN: 'lxdc. cWN:            .xM0'   dM0'   '0Md:XMk..';oxl,       oWMk.         ;XWc,KWl    :XNccNN:   ,KMo:XMN:   .xMO. 'lkXNKko,                 //
//                .kWWO;     .ol    cNNc'. cNNo,;....  cWN:             dM0'   dM0'   '0Md'OMO;;:,....       .xWN:         ;XWc.kMXl.  .k0,;XNc   ,KMo'OMWo   .xMO..;...;oKWNo                //
//                 .cONNOl;,','     .xMXc  .lK0;.,dKO' lWNc             :XX: ..xMK,   ,KMx.,OXd. .lOXc        .:kOc.  .;oc.:NWl .xXNk:.,l, .lKk.  :XMd.'xNXo. .kM0';00o,..oNK:                //
//                    ':clc,.        'll,    .;,';;;,  ,ll'              .:;...;lc.   .cl;. .,;'',:;;.           ';'.';;;. 'll,   .:cc;.     .;,..'cl;   .;c;..:lc. ..','';,.                 //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                    ..                                                                                                                      //
//                                                                   .xd.                           .l'                                                                                       //
//                                                                   .kx.'c,;o,  .    .;;.;c;l;   ..,x;,o'.;, ;d,.,,..,l;                                                                     //
//                                                                   .kx..xKldO,..     :c':0ooO, .. ;KccK; c0,lK, .cx, c0l                                                                    //
//                                                                   .kd..kK,.xO'     ;0o.,0l.xOc,  ;KccK; cK;l0'  'Ok'.lc                                                                    //
//                                                                    ;;.,:'  .;.     .:,.'c, .ll'  .l''l. 'l',c.   .::..                                                                     //
//                                                                         .c;.                                                                                                               //
//                                                                          ..                                                                                                                //
//                                                                                                                                                                                            //
//                                                                                                            ',                                                                              //
//                                                                                                      .,:lodO0x:''cdxxoccdxoldl.         .;:,'::'...                                        //
//                                                                                                 ':loooOWWOkKNNX0XNKOdcxXK0XXKk;.    .:oxkO0KNWWX0Okoc:,.             ..                    //
//                                                                                               .dOKWWKOXXOKWMWX0O0x;.',cOXWNKkxOd.  .dNXXKKNWKOO00kd0NK0Od'       .'cxkddxx;                //
//                                                                                             .ckX0XWNKNXkxk0KXKOkdc...,ckKKXKO0XkccdOXNNMMMWKl'';c:ck00K0xl,.    ;kOOkdoxO0d.               //
//                                                                                             l0KKXKdc;:c,',,,;;'.....,odlxO0KXWMWWWNKkdxO000d;,;;..,lldXN0kOxddld0kd0K00OkO0o.              //
//                                                                                           .dXNNN0l;,,;;;;;;;;,'....,lkkOXOokXXXOxO0x;'.',,;;,..   ..,cONWNkkNMMMWxoKx;;,;ldkk;             //
//                                                                                           .kKkkkdodxOKK0Okxkdc:'':ccdKWWWXxdOKXd;xK0OxdlcxOko.    ..':odKKOKWMWWN00Xkc,':d0WWNOoooxkkOd    //
//                                                                                     .cxdlclKX0kxOXX000OOKXWMWXKkdk0KNX0XNK0XWWWKOKkllkKkkKkoc.      ....lkkXMMMMXkKWNKxlodOKXXWMNKKNNNN    //
//                                                                                    ,kK0KKXNWMMWKKXd'':odkKWKOXWWXXWWXNWWXxoOXN0oc;....',;;..         ...'ccxNMMWNWWKxdkddkx0WWWMNKOKWMN    //
//                                                                                   :OOdollONWWNKdc;..;xOOxdoox0WNXNNKkk0KXkccodo:..    .....         ......,OWWNWWMWXdldxkO0XKXWWWNWNXKO    //
//                                                                                 .oK0d::;oXMWX0Od,.,;..... .oXXKdlooc;;,;cc;,,,'.....  .....        ......;dXN0kOXX0xc;;ldOkxkKKOOOkxool    //
//                                                                                 :0KNk;..cKMWkll:..:;...    cxc;;;:::clll:;'..... ..           .;;..;,..'xNMWNKOOOo;'',,,:odd0XXXNNXOoll    //
//                                                                              .;:kNNKl'.'xNNXko,      .     ....',;:cldl;'.....    ...:oodolooddodkOxoc.,OWN0Okddko;,;;:lxxdkKWWWWNWNOdo    //
//                                                                          ..'oXWMMWKl'''cKXkOx:,.           ..........''...        .:0KKXK0000KNWNWMNOxx0NNklxkOXWN0Okc.':odxkOOdllkNWK0    //
//                                                                      'ldOKKKXMMMWWO;';;lXNk:'.........         ........          .;0WK0KXKK0xkKWMMN00XWWWWXXWWMMWNXX0c:o;:llll:'',:okXW    //
//                                                                    'oKXXNNNXNWWKOXkcc:;dXKk:','......           .             .,lkNMMMMMMWNNWMMMWNKdlkKKXWMWXNWKkxxolkKx;:c;,'......,lO    //
//                                                                 .;x00xlcldx0NMNO0Kxd:. :Kkl:,'''..                           'lKMMWXKKNWNkokKOkXWXkooxkkO0OxdxOxc,''';c;,,,'... .'..,cx    //
//                                                                .dX0xxkc,lxO0NMWWNKkxllokNXd:'..'..                         .lKWNK0Oxl:lkx;':l;:kN0o::;,,,'.,,,,;'.....',,''.,coldX0k0NW    //
//                                                                ,0KOX0dxKXKNWMMMMMWNNXXKWMXd:,','.                          .:xkl:::;..',,..''..;lc,'''.   .................,kNNNXWMMMMW    //
//                                                             .':kNX00dlOOldXMNKKKXNWMWXOKWXd:,,';,                            .........................     ...            .'x0xOKXXXXX0    //
//                                                       ...;o0KXWN0dkK0O0kxKWMKl;,;cdOKNKkOkc,...dXd.                                 ..................                   ,x0KXdcccxx:,,    //
//                                                   .ldx0XNXXKKXK0KXWMWNWMMMW0o:'.....,:::;;;,;cdXXd.                                 .......... .......                  'OWMMWOc,:xd'..    //
//                                               .;:l0KO0NWNXOldkdxkXWWWWWWWN0xlc;'.......'',,:OWWNx'.                                               ..                 ,odOXNNWWOod:....     //
//                                             .:OXKK00OXXkkKd,:d0XNWWXXKOKWKxdl:cc::c,....'',dNMXxc,.........                                                         'OKxddkKXK0d;......    //
//                                             cOxoclldKWN0K0c'oKX0dxOkkxdkXKklccOX0KXOkkxxdolOWW0l:,.......                                                           ,kd;'.:kXKkdl,..,lk    //
//                .;,.                      .,dK0kxddd0WMK00d:lO0kdlodoodx0NWNKNWN0kKWMMMMMMMWWWWN0x:'.....                                                             'dOx:c0WNx:::,;dko    //
//      .colokkkkOkdc'...;c.             'cd0WMWWMWXk0NNWWNNOxxkOolodddk0NMMWWMMMNOONWX00NMMMWNNNWNk:'......                                                            .oK0k0XKkc'.;lc;,'    //
//    .;kWMMWNWWXx,..coo0Xk;            ,OK0XWKkOOxk0XXO0NNNKx:ckxloOXNWMMMMXXXX0xONWXkookKK0OO0OOxl;,,......                                                            .:;:c:::'.',,,,,;    //
//    ONMMWKOKWWKo.  .':O0c.            :OxdOKKxoocdXN0xxOkKWKOOXOlcd0NMMMMWKkxxoON0doccccllcc:clllll:;,'....                                                              ........''',;;;    //
//    MMMW0ldXWXKkdc',dXNo.            .lKXXNNNXXKOxOOdod0NNWWWMW0dokXNNXNWXOOOxoxOo;,,;;;;;:cccccc:,........                                                             ..........',,,,,    //
//    NX0x:,lXMWWWMNXKKOc.           'd0XK00000000XNXKK00XNK0OOOO0KOkOKKKXNXK0Okdooc;,,,,,,;;;;'...                                                                       ...........,,;;:    //
//    0dc'.;xNWWNNNKd;.            .lKKkO0K0kxdlclokXNKO0XOxdodkKWWWMMMMWNNWWNKkdolc;;,'','..                                                                              ...........',;;    //
//    ;;;'.,kNNKOkd;               .kNK00kxooddl;;lkXNKO0OdxkOXWW0xOOxdddcokkOXXKklc;,:x0KOo:cloxddo;...                                                                    . ........',,,    //
//    ';;..'dXNXOl;.                c0ko;',;:cc:;:lONWMMWKKNMWOxKk;:c:;;;'.',,l0KdccokKNX00NMMNXXXKOOk0XOdc'                                                     ..       ..  ........,:cc    //
//    ..',:loONWk'                .cOKkxc,;:cllolldxKWMMMMWXXKl','.''........,:dxodOXWKdlokXX0ddk0Oxoclx0KKk:.                                               .   ..  . ....,'.......'oKXNN    //
//     ..'lkOOxl.               .xXWMMWKxddddxddkXWMMMMMMWKkokx;... ':coxkxl;::codKWWXx;';xk:,'',,'.....'cdkkc,.                                                   ..,cdkOKNXOkxo::ckNMMMM    //
//      ..,clc,.                .cKWWWX0OOOOOOkONMMMMWXXKkl:;co:,'.lKNN0xk0OO0K0O0NWN0dc:c:,'''.......  ....'cxl.                                        .;,';c;:odkKNMMMMWWNNWWWWWMMMMMNX    //
//      ..'',,'.                 lNWWNK0KXXX0OKWMWWKxoccclkOO0XKK0KX0dc;..';o0NWWMWKOkddoolccol:::,..   ........                                        .xWNNWMWWMMMMMMMWK000XNNWMMMMMWXkx    //
//       ...'..            .:odoldKWMWNNMMMMWWMMMWXo,;:;:ONWMWNXKNMNKOx:...,lx0KXNXKXXNNNNNNWWX00XXOko'                                             .cdkKWMMWMMMMMMWXKKK0kO0XWWWMMWWXKKkdd    //
//       ..';;.        .':dKWWMMMWWWXkokNMMMWWNNWXd:dO00KNNNWMWWMMMWWMWXkc:odkO0KKKNMMMMMWX00NNOx0NWNNkc;;'.                                   ...':OWMMWWNXX0KXXK00OOOddkO0OOO00OOOkxxkkO    //
//    ....':dOk;.  .,ck0XWMWXNMMWWN0xlcxXXNXOkddKOlxK0KKXXXWWWWWWMNKKNWWWNNWWWWWWMMMWNNWNX0kxKXKO00K0O0XNWXOd,  'odoc.                         :ddkXWMMWKOkxkxxxkxxxkKXOx0XNKOxddxxkkxxKNW    //
//    .. .;OWWWX0dlOXNNNXNWWWWWWMMWN0xllOKkdc::lkxdKXkOKX0XWXKNNX0kdook0KNWMMWNNMMMMWXK00K0kxkkddoolcclooooodd, 'oxoo:.                       .lxd0WMMMW0xxxxkxxxkOO0XWWXKXNNKOxk0XXKKKXNN    //
//       .;xKNWWMWWWNXNK0XNNWWNWMWNKklcldOko:;:o0NWWNKNMMMMNkxO0xoolc:cloxKWWNNWMMMWWN0OOkxooxxdolc;,,,,''.....  ......                    .,:oONWMMMMMMNXXXKXXKKXWNNNNNX0KXK0kkOKXK000KK0    //
//        .,dXWKKWWWNKXNXXK0KNMWK0Okko::::lO0kOXN0ONMMMMWNXkollolcllc:clloox0NWWMMNK0kool:;,;cc::::;'......''.........                   'dKNWMMMMMMWWMMMMMMMWNNNNMMMN0OO0KKKKXNNNNXK0000O    //
//        ..:dxdkO0XK0XWWNWWWWWWNKK0OO0xccOWMMW0xolx0NWN0kdl:,;;,,,;;;:cclclok0KK0koc;'......''','........';,............            .cclOWWWMMMMMMWXXNNNWWWWWNNWWMMNKOkkO000KNWNXXKOkkkkk    //
//        ....';ccoxxO0KXNNNWMMMNNWWNK0XNNWMWKOdllooxkkdlc::;,,,''',;;;;:::::cloddl:,''...................................          .lKXNWMWMMMMMWNKKXXXKXNWWWWNNWMMWKOkkkO00O00KXX0xdxxdx    //
//        ......',;cloxOKXK0XWMMWXNNXOk0XKKKKklcccdxdddl:;,,,,,''',;;;;;,;;;;;;::c:;;,,'''''''............................           .lOXXXNWWMWXKKKKXXNNNWWNXKKNWMWN0OOOkkxddxO0KK0xolooo    //
//        .......'''':kKNKOk0NWNXNWWNKKK0kxoolcc::oolodc,'''',,''',,,,,,'',,,,,,,,,;;;,''''''''''..........'''..........            .,dOOO0XNNNX0OOOOOKNNWWX00KXNWWX0kkkxddddx0KKK0kdoooll    //
//       ...,;::,''::l0NNXOOXNXK0KXNNXXXKOdlc;;,,'....'......'''''''''''''''''''''',;,''''''''''''.''....'''''.......               .o00kxOXNXKK0OkkkO0KKKKKKNWWNXXKOkdooooodkKK0kxdooolcc    //
//    .  ...'ckkkkxx0KKXXX0KXKOxxxxkO0000xl:;,,''...................''''''''.......'',,,''''''''''''''''''''........                ,oxOkxkkkkOOkkkkkO0OkOkkk0KKK0Ok                          //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OVTC is ERC721Creator {
    constructor() ERC721Creator("Over the Clouds", "OVTC") {}
}
