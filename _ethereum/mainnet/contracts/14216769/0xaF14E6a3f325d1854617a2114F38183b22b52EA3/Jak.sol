
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ColbyJack
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                              ...                                                               //
//                                                          .:oxxxxxxdddolc:;'..                                                  //
//                                                     .,:lxOOxlcccllooddxxkkOkxxddol;.                                           //
//                                                .':oxkOkxdc::::::::::::::::::cloodk0kdxxxddddool:;'..                           //
//                                            .'cdkOkdlc:::::::::::::::::::::::::::::clllllooooddxkkOkxxxddoc;'.                  //
//                                      .':odxkOkoc:::::::::::::::::::::::::::::::::::::::::::::::::::clloodxkOkxoc;..            //
//                                   .:okOkxolc::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::cldxOOkkxdol;.     //
//                                 .oOOxl::::::::::::::::::::::::::::::::::::::::::::::::::::::::ccc:::codxxxkkOOOOkOO000OOXx.    //
//                        .';loddddO0o::::::::::::::::::::::::::::::::::::::::ccclloodxxxkkkOOOOOkkOOOOOkxdoollcc:;,,''....x0'    //
//                  .';codxkkxdoooolc:::::::::::::::::::::::coxxddddxxxkkOOOOOkkkkkkxxddollcc:::;'',:::,...................kO.    //
//              .:oxkOkxdlc::::::::::::::clloooddxxkkkkOOOOOOkxddxxxdoollcc:;,,'..........................................'Ox.    //
//         .,ldxOOkdooooddddxxxxxxxkkkOOOkkkkkkxxdoollllcc:;,.............................................................;0d     //
//     .:okKWWXKOkkkkxxxxxxxxddoooolllc:;''...............................................................................oXl     //
//    .OKdolcc:;;,'.....................................................................................................,kO:.     //
//    ,Kx...............................................................................................................cKc       //
//    ,Kx..................................................,x0000000000k:.......'lkkkkkkkl'.....,odddddddddddddoooc;....,kO'      //
//    ,Kd..................................................;0WWMMMMMMMMNl......cOWMMMMMXd,......:KMMMMMMMMMMMMMMMMWXOl'..;0x.     //
//    ,Kd...................................................;:lkWMMMMMMNl....:OWMMMMMNk;......'';odkNMMMMMWNNNNWMMMMMWO:.;0o      //
//    ;Kd........................................,;cloddxxkkxx::OMMMMMMNo..;xNMMMMMMNklloodxO0KKXXk:kMMMMWx;,;;:oOWMMMMK;cXc      //
//    ;Ko......................',,;;'........;lk0XNWMMMMMMMMMMk:kMMMMMMNo,dXMMMMMMMMWWMMMMMMMWNXK0x:kMMMMWo.......oXMMMMxoKc      //
//    ;Ko......;;cclllll;....;kKXXNNO:.....:kNMMMMMWXK0O0XWMMMO:xMMMMMMWKKWMMMMMWNNNWMMMMK.........'OMMMMWo........xMMMM0xKc      //
//    ,0o......lNMMMMMMWd....oWMMMMMMNd'..lXMMMMMXxc;'...;xNMMK:xMMMMMMMMMMMMMMMO:;;c0MMM0:,,;;;;;;'kMMMMWo........xMMMMXOKc      //
//    'OOolc,..llokNMMMMk...'kMMMW,MMMW0::KMMMMM0;........'xNNO:kMMMMMMMMMMMMMMMNOc..dWMMMNXXNWMMMx;kMMMMWd.......:KMMMMXOKc      //
//     .,:ldkx:....dWMMMO'..:KMMM0..MMMMXKWMMMMWo..........';;,,OMMMMMMMWWWMMMMMMMNk;cXMMMMMWNXK0kl;kMMMMWo.....;dXMMMMMkoKl      //
//          .o0o...oNMMMO,..oWMMMk...MMMMMMMMMWo..............,OMMMMMMNx:clkNMMMMMMKx0MMMW:.......,OMMMMMKkkkk0NMMMMMNk,cKc       //
//            oKc..oNMMMK;..xMMMMNKXNMMMMMMMMMMMO,.............,0MMMMMMNl....cKMMMMMMNNMMMWOllodxkOKNMMMMMMMMMMMMMMWXx:..lX:      //
//            ,Kd..lNMMMX:.,OMMMMN0kdldXMMMMMMMMWOc.........,cd0WMMMMMMNl.....;OWMMMMMMMMMMMMMMMMMMMWKkkkkkkkOOkxdoc,....oK;      //
//            cKl..lNMMMNc.;KMMMNo.....:0WMMMMMMMMN0dlccloxOXWMMMMMMMMMNc......'xNMMMMMMMMWNK00kxddol,...................oK;      //
//           :0x'..cXMMMNo'oNMMMK;......,kXXNMMMMMMMMMMMMMMMMMWNWMMMMMMNc........:kKNWMMWXd;'............................dK,      //
//       .,lxxc'...;KMMMWK0WMMMMk'........,,;d0NMMMMMMMMMWNKOxc::yyyyyy:'..........';clc:,...............................dK,      //
//     'xkxo;......,0MMMMMWNKOxl;..............;lodddddolc;'.............................................................oK;      //
//     ;Ko.........'OMMMMKl;'............................................................................................dK,      //
//     ,0o.;okko,..'kMMMMO'..............................................................................................x0'      //
//     '0xlXMMMWx..,OMMMMO'.....................................................................................''',;::cd0o.      //
//     .OxdWMMMNd,;xNMMMMO'......................................................................';;:cllllllodxxdooddoooc'        //
//     .kx;xNMMWXKNWMMMWKl..............................................................',;:clldxddooolccccc::,.                  //
//     .xk..:ok0XXNNXKkl,...............................................',;:cllloddxxxdddddoolc;.                                 //
//      dO'.....',;;,'..................................',;:cloddxxxxxxddddoollc:;,'....                                          //
//      dO,..................................;coddxxdxxdddddolc;,'......                                                          //
//      o0,.....................',:cloddxdxddxo:;,,,,'..                                                                          //
//      lK:......',;;:clloddxddddddol:;,'....                                                                                     //
//      .lddddddddddooolc:;,'....                                                                                                 //
//        .';;,'..                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Jak is ERC721Creator {
    constructor() ERC721Creator("ColbyJack", "Jak") {}
}
