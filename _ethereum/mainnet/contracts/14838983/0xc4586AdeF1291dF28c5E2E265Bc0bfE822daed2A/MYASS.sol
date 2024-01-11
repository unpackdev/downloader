
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Meka Yolo Armed Shitty Shitcoins
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                         ,x000000000K0000KKKKKKKKKKK0;                             .oNNNNNNNNNNNXXXXXXXKXXXXXKK0d,.             //
//                          .o0000000K000000KKKKKKKKKKKo.                            ;KNNNNNNNNNNNXXXXXXXXXXXXXKk:.               //
//                           .cOKKK0KK0000K0KKKKKKKXXKXk'                           .kNNNNNNNNNNNXXXXXXXXXXXXX0l.                 //
//                            .:kK0KK00000KKKKKKKKKKXKX0:                          .lXNNNNNNNNNNNXXXXXXXXXXXKx,.                  //
//                              'x000000000KKKKKKKKKKKKKo.                         ;0WNNNNNNXXXNXXXXXXXXXXXOc.                    //
//                               .oO0000KKKKKKKKKKKKKKKXk'                        .xNNNNNNNNNNXXXXXXXXXXXKo.                      //
//                                .ck000KKKKKKKKKKKKKKKK0;                       .cXWNWWNNNNNNNXXXXXXXXXx,.                       //
//                                 .;xKKKKKKK0kOKKKKKKKKKo.                      ,OW0xKWNNNNNNNNXXXXXXOc.                         //
//                                   'd0KKKKK0c'cOKKKKKKKx'                     .dXk':KWNNNNNNNNNXXXKo.                           //
//                                    .l0KKKKKk' ,xKK0KKK0:      .''.           :0d..OWNNNNNNNNNNXKk;.                            //
//    '.                               .:OKKKKKc..,dKKKKkl'..  ..''''. ..      'xo..lNNNNNNNNNNNN0c.                              //
//    0d:'.                             .,x0KKKk,::'o0k:':oOk,.''''''.,k0d:.  .;::,;0NNNNNNNNNNKd'                                //
//    000Odc'.                            .oxox0l,do',,:x0KKKd..''''..dXKXXO:. .ox,oNKk0NXXXNXk;.                           ..    //
//    0KKK00ko:'.                          ...,;;.:0d'lKKKKKK0c..'''.:0KKXXXXl'dKc,do;.oNXNX0l.                          .':dO    //
//    0KKK00000ko:..                         .dd:',xKxodk0K00Kx,.''.'xKKXXKOxdkXx.'cdx,lNNKd'                         .,cx0KKK    //
//    0KKK00000000ko:..                      .lk0Oc:x00kddddk00o....lKKOxxxxkKKOc:OXKd'lXk;.                      ..;okKKKKKKK    //
//    0000K00K0000000ko;.                    'ddddocclodOKOxddddc;;cddddxOK0xddoodkkkd';l.                     .'cdOKXKKKKKKK0    //
//    000000000000000O00ko;.                 c0K0Oxddl::lodkOxdxxxoxkdxOkdoolldxxk0XNK:                     .,cd0XXKXXKKKKKK00    //
//    000000000KK0000O00000kl;.             .;ccloddddodoc;:cdOkkxdxkOdcc:lddodxxxdolc;.                ..;okKXKKXKKXKKXKKK000    //
//    00000000000000000O00000Oxl;.       ,::xkccddol,..,;,''.:xxddxxkx;.'',;,'.,lddklcxkc;,          ..:dOXXXXXKXKKKKKKKKK0000    //
//    00OO00000000000000000000000kl,.   ;koo0dlk000x'.....   .,:cclc:..    ....'xXKK0odKxoOc      .,cd0XXXXXXXXKKKKKKXKKK00000    //
//    K00OOO00000000K00KK000000000K0kc..cocdKkdox0O;...'co,.. ......... .'oc'...:0KOddOXkcdo.  .;lxKXXXXXXXXXXXXKKKKKXXKKKKKK0    //
//    K00000000000O000000KK0000000KK0c;dO0do0K0xdddo:,..::;o:..'....'..:o;c:..,:oxddkKXXdxK0k;.oXXXXXXNNXXXXXXXXKKKKKKKKKK0000    //
//    0K00000000000000000KKK00000000c,xK0KklkK000OdoxOd,   ..':c:;;;::'..   'okxodOKKKX0okXKXO,:KXXNXXXXXXKKXXXKKKKKKKKKK00O00    //
//    00000000000OO000000KKKKK0000Kx.:0KKK0loO0K00KkokKOdc;,;oOOooxldOd;';:lk0klxKKKKK0do0XKKKc,kXXXXKXKKXKKKKK0KK0KKKK0000000    //
//    00000000000000000000KKK00000Kd.cKKKKKOxxdd0KK0ddKK000OxdlcldOo;lodk00OOOooOKK0xdddOKK00Kl'xKKKKKKKKKKKKK0O00O000000000OO    //
//    000000000OOO000000000000KK0xl:.;0XKKKKKXk:dKKXOooxO00000o;cdkl'o0OOO0kxlcx00Kx:dK00KKKKO;,kK0KKKKKKK00K0OOOOOOOOO0000OO0    //
//    0OOO00000OOOOOOOOOOO00000d::coc:xXKKKKKKKlcOKKXKOxlo0K00d;:lo:,oOO00dcoxOOO0OlcO000O000o.,dO00000KKKK00OkOOkxxxxddooolll    //
//    OOOOOO0OOOOOOOOOOOOOO0Od;;oO0KKd;xKKKXKKXk;,cldkO0c'looxo'.''..collc,;xxolc:,,d0OOOOOOo',:,,,:ccc:::;;;,,''..........       //
//    OOOOO000OOOO00OO00OOOO:'ckO0KKk;..',;;::cl'    ..''';'...      . .',....     .::::;;,'.,k0Oxl;.                             //
//    llllllllcc:ccccc:::::;.,k0000d' .;llc::;,'.......;odOd'          'dkdl'...     .....'..'dkkxkOxc.                           //
//                       ';. .cO0kc..'o0KKXXXKKK0Okxdoldkkxl,..     ...,oxxdc:::cccodxxkOOOkc..lkkkkOo.                           //
//                     .lOx'  .:l. .:OK0KKKXXKKKKKKKKKKXXK00kxdd:'.:dxkkOO000000OkOOO00000OOOo'.;coxd,    ..                      //
//                    .dOkl,,;;;....,xKKKKKXXXXXXXXKKKKXXXXXKKKX0olkXKKKK0000000OOO0000000OOOd'   ...   .cddc.                    //
//                     ;l;:kOOOl,':dc,l0KKKKXXXXXXXXKKKKKKXXXXXXOooOXKKKKK000O000000000000O0d' .''.......;cc;.                    //
//                    ,dx:,odddl;,cO0;.:k0K0KKKKXKKXKKXXXKKXXXKXOookXKKKKKK00000000O00KKK00o,..,kOl:dxl;'',.                      //
//                   .cc,.........':c'..,oO0000KKKKKKKKKKKKKXKK0xccdOO0KKKKKKKKK000O00000Ol''. .;;,,coc;:oxc.                     //
//                   ...            .  .'':x0O00O00000OOkxdolcc;'...';:lxkO0K000O00000OOkc'''.  .   ....;oo:;.                    //
//                                      ''.'okkkkOkxol:;'.....        ....,:lodddxOOkxkx;....     .     ..':l.                    //
//                                      .,,..''',;,....          ....        ....,;;;;;,.'.               .',.                    //
//                                       ';,'.           .................          ...';:'                ...;:,..               //
//                                      .,col,.    .............................     .,dkx:.                .:oddoc:;'..          //
//                ..;cc'.              .;loo;..........................................lxdl;.              .cddddodddol:,'...     //
//            ..,:ldxxxdl;'........  ..;:cc;...........................................'cllll:.   .    ..';odddddddoollllllc;,    //
//        ..,:lddxddddddddolcclllo:..;:cccc,.......................................... .;llccc;..:lclcclodddxdddoooolllllllccc    //
//     .';cdxxdddddddddoooolllooodo;.'::ccc;.    ...................................    .;ccl:..cdodddoodddooollllllcccccc:cc:    //
//    codxxxxdddxddodddooooooooooodl,.'cooooc'.      ...........................        'cl:'. .'coooolllllllllllllc::cc::ccc:    //
//    dxxxxxddddddoooddoooooooooooo,  ...,,:ll:,.             ..                      .',,.. .   .,:cccclllllllcccc:::::ccc:::    //
//    ddddddddddddoddooooooooodoool.  ..   ..',;:;'.                                 ...           .,:cccccccc:::::;::::::::::    //
//    doodddoodooooddooooooooooool,......     ...,;;,'...  .....    .................    .....      ..,:::::::::::;:::::::::::    //
//    ddoodooooooooooooooooooooo:.  .,'.. ...    ...',,'....'''',,,,,,,,'.........   ....',,;'        ..,;;;;::;;;;::;;;;;:;;:    //
//    ddooooooooooooooooooooool,.   .,'....';;,..   .......................  ..   ..';,....''.          ..,;;;;;;;;;;;;,,;;;;;    //
//    doooooooooooooooooooodo:.     .ll:..'',,;;,'..      ................    ...',,,,....',,'            ..,;,;,;;,,,,,,;;;,,    //
//    dddooooooooooooooloolc'.      'llc..:lc:;,,,,,'  .','..............','....'''''',,'..,,.              .',,,,,,,,,,,,,,,,    //
//    dooooooooooooooooool,.        .'''..';;;;,'...   'cccccccc::::::::::::,..,;,,,,,,'.....                 .',,,,',,,,,,,,,    //
//    oooooooooooooooool:..        .'.'''..           .;ccccccc:cccc::::::;;;;...      .......                 ..',,,,',,,,,,,    //
//    ooooooooooooooooc,.          ........           ':::c::::::c::::::::;;;;;,.        .....                   ..',,,,,,,,,,    //
//    ooooooooooooool;.                              .;::::::::::::;;;:;:::;;;;;,.                                 ..',,,,,,,,    //
//    oooooooooooooc'.                               .:c:::::::::;;;;;;;;:::::;;;.                                   .';,;,,,,    //
//    ooooooooooooc.                                .,:::::::::::;;;;;;:;;;;::;;;'.                                   ..,,,;,,    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MYASS is ERC721Creator {
    constructor() ERC721Creator("Meka Yolo Armed Shitty Shitcoins", "MYASS") {}
}
