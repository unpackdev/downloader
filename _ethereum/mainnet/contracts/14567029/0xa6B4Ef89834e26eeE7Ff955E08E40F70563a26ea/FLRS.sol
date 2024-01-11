
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: flourish
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                               //
//                                                                                                                               //
//                          .lk0KKKKKKK0xl,.                                                                                .    //
//                        'cx0000KKKK0kdc,..                    ....'''',,;;;,,'...                                              //
//    c,.               ,oOKKKKKKK0Oxoc;'..                     .........'',;::;;:;....                                          //
//    NX0kdoollcccccllokXNXXXXXK0Okdl:,..                       ....'''..... ...........                                         //
//    0000KKK00KKKKKKKK00000OOkxxdol:;,'....                  .';cloooolc:;,'...........                                         //
//    xkkOOkkkO000OOkkOOOOkkkkxdoolccc::;,,'......................'',:coooolc;...........                                        //
//    xkOO0Oxdxxdoccclooooddxxxdodxxxxxxddolc::;;;::cccc:;;;;;,,'''......',;::.... ......                                        //
//    odxxdolloddolooll::c:;;;;:clodxkkOOOOkkxdolllllcccclcc:,'',,'''....    ....  .....                                         //
//    ooooloddoooooc:c;'..''''.',;;;:::ccllllooodxkkOkdllc::cc:;;,'.........                                                     //
//    :;:lollollloocodc,..',,'''',''',;;;:;;;;;;;::ccloxOOxc;,,;cc:,,'.......                                                    //
//    ,;:looxkxxxxxodOk:....',;:::;,,,;;,,,''',,;;;;;;;:cldkkd:,''',::,''...                                                     //
//    ;:coxOOkxxoooooxk;      .,:ccclllllc:;;,,,,,''',,,;;;cldxxoc:'...',,....                                                   //
//    ,;ldkkxxdololcoodxc.      ..,;:cllloooollllc;,,;,'',,;;;cldxxxl;.........'.......                                          //
//    ,codxxxo::cll;:olcoo:'.    ...',;;:clloooooollllc;::,',;;;::cclll:,.  ..;:,.........                                       //
//    ;cclloo;.';:;;,,clc:cll:;'.    ...',;:clllllcccclodoc::,',;;;;;,,',,'..'''....''..                                         //
//    ,,;;:l;.......''.',;;;;;:::;,.........',;:cc:,';cdkOkdo:;;,'''''........ ......''.                                         //
//    .'',;,.     .....................     ..',,...,cxkxkOOOxoc,........         ......                                         //
//    ....          .................       .......;cloddddxdxkxol:,'..       .''..   ..                                    .    //
//               ..'',,,;;;::::::::::::::ccc:;;''''''',,;;:cccc:ccc:,....  ...;:;'.                                         .    //
//            ....';:cllodxkkOOkkkkkkkxxxkkkkkkxoc:,...'..''......         ........                                        ..    //
//         ..',:cloodddxxkOO000000KKKXK0000OO0KXXK0ko:'........                ....                                        ..    //
//        ...';:cloxkO00KXXXNNXXXXXXXXXKKXXKKXKKXNXXNK0x:'.                                                               ...    //
//      ...',;:clloodxkkOO000KKKXXNNNNNXXXXXNNNNNNNNWNXXOxl'.                                                                    //
//    ....'',,;cloodxxkkkkOOOOO000KKXXNNWNXXXNNNNNWWWNNNKOd;,....                                                                //
//    ...'',;;:cllooooollllloooddxxkkkOO0000OO0000000000Oxol::;;'..                                                              //
//    '.....',;;:::ccc;.          . .....................  ..                                                                    //
//    ;'......',;;:clo;                                                                                     ..'','...            //
//    ,;,'......',,;:c,                                                                                      ...'''''..          //
//    .................       .,.'.    ..        ''.'.     ..  ..     .,.''     ..    .'..     ..  ..        .'''''.......       //
//     ............  ..       :l''.    ,;       :;  .:'   .:.  ;,     :c.,c'   .:'    ;:,'.    :c..c;         .,,,'',,;;,,..     //
//         .....',;;:c,       ;c...    ,:.      :;. .:'    :; .:'     :c'l:.   .:'    .,,c,    :c..c;         .':lc:,''''....    //
//           .....';::,       ..       .,'..     ''.'.     .'''.      .. .'.    ..    .'.'.    ..  ..         ..':oooc;'..'..    //
//          . ..,;;:co:                                                                                       ..',:lddol:'..'    //
//    ;'.      .',,coo'                                                                                       ..,:;:lddooo:..    //
//    ool:.     .,coo;..                       .............                                                ....':c::coddool,    //
//    :clxl.     'coocc:;,'.....       .,:oooddkOO0000000OOko.                                ......       .,,''',:ccccoxdooo    //
//    .,:coc.    .:oc:clc,,'......    .;ldkOO00XXNNNNNNNNNXKd.                                 ....''.     .'::,,,;cllcloxxdd    //
//     ..,;lc. .  ,lc;c;.'... ..''....:odk000KXXNNNNNNNNNXKOc..                             .  ...'..'.    ..;c:;,;;clllldxxd    //
//      ...,c;    .,;:;.... .:ll:;;;cdxxk00KKXNNWWWWWNNNXKkoc:.                              ......,'.'.   ..,ccc;,;:clllldxk    //
//        ..'c'  ..'';:;,'clldxdodxxxxxO0KKXNNWWWWWWNNNXOdllc'...                            ...'...;,.,.   .,:llc;;;:clolodk    //
//         ..,;...,;;coollodddddxkkkO0KXXXNNWWWWWWWNNX0o,.,;,,,,''....      ..            .,;,';:;,''c,',.  .;;cll:,;;:looood    //
//           .,,.';:cooccddxxkkO0KXXXXNNNWWWWWWWWNNXOl'. ..',............          ..'..',:okdlcl:';':o,''. .;;:llc:,;;:loooo    //
//            .,,;ldxdllxO0KXNNNNNNNWWWWWWWWWWNNNKx:.   ............   ..          ..,;:ldxk0Odll:.;:,oo;,...;:;clcc,';;:looo    //
//             .:cdkkxkOxx00KNWWWWWWWWWWWWWNNNKkc'      ...  .....''........     ...'',;:codkOkoc:'.c::dl;'. ,c;:clc:'';,:llo    //
//             .;c:clollollkKXXNNWWWWWNNNXKOd:'      ......................................,:oxxoc,.';;cdl;. .::;ccc:,.';,:ll    //
//             .','.',l:';:;:ok0XXXXXXK0kl,.      .....................'''......             ..';:ccccccccc;'.;:;;:c:;..';':l    //
//             .......,c:..;,,'',:cccc;'.       ...'...'''.................'''''...                ..',;;::clloodddddol:;:;',    //
//              .'.....',:'...'...            ....'.................'...                                     .....',,;;:::c:;    //
//              .....  .......               ......           .,;:;,...'.....                                               .    //
//               ..                            .               .';:lc:,'.......                                                  //
//                           ..  .......                        ..':ldxdoc:;,,''......                                           //
//                    .....'...  ';;,,;;'.                       ..':lodxkkkkxxxdddolc;..                                        //
//                                .';col:.                        ...,;:cclllcc::;;;,,'.                                         //
//               .                  .;dxl'                         ............                                                  //
//              ..                   .lxo'                                                                                       //
//                                    .lx,                                                                                       //
//                                     ;d,                                                                                       //
//                                     .lc.                                                                                      //
//                                     .dx,                                                                                      //
//                           .... .'.  .od:.                                                                                     //
//                                                                                                                               //
//                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FLRS is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
