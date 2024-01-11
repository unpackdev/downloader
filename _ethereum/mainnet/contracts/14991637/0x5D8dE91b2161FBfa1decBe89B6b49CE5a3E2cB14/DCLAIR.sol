
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Diana Sinclair
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                      ...........                                                                             //
//                                                                 .....'',,,,,''..........                                                                     //
//                                                             ....'',;;;:::::;;;,,,,'''.....                                                                   //
//                                                            ..',,;;:::::::::;;:;;;;;;;,,,,'...                                                                //
//                                                           ..',,;:::::::::::::::;::::::;;;;;,'....                                                            //
//                                                          ...',;;::::ccccc:::::;::;;,;;;;;;;;;,''...                                                          //
//                                                          ....',;::::ccccccccc:;::;;;;;;;;::;:;;,,'...                                                        //
//                                                           ...',;;;:cccccccccccc:::::::::::::::::;;,''.                                                       //
//                                                            ..',;;;:cccllllllcccccc::::::::::::::::,'...                                                      //
//                                                           ...',;;::ccllllllllcccc:::;;;;;;;:;;cllccc'...                                                     //
//                                                          ..',,,;::cclllolllllccc::;;;;,,,,;',clc::cl:.',..                                                   //
//                                                         ..',,;;;:clllooooollllccc:::;;;;,,:,':lcclc:,,;,,'.                                                  //
//                                                        ..',,;;::cllooodoooooolllllcc:;;;;,,,,',;;;;;;;;;;;,.                                                 //
//                                                       .',,;;;:ccloddddxxxxxddddooollcc::;;;,,;,,,;::::::;;,...                                               //
//                                                      .',,;::clloodxxxkkkkkkkxxxxddooloollccc::::::cccc::;;;,'''....                                          //
//                                                    ..',,;:ccloodxxkkkOOOOOkkkkkkkkkxdddddddoolllllllllc:;;;;,'.....                                          //
//                                                   ..',,;;clloddxkkOOOOOOOOOOOOOOOkkkkkxxxxddolollllllll:::;;,..                                              //
//                                                  .',,;;:clooodxxkOOOOOOOOOOOOOOOOOOkkkkxxxddoooolllloolc:::;,'...                                            //
//                                                ..',,;:clloooodxkOOOOOOOOOOOOOOOOOOOkkkxxxxxxddooooodooolc:;;,'..                                             //
//                                                ..,;;:lloollodxkkOOOOOOOO0K0OOOOOOkxddddoodddxdooddddddool::;,,'..                                            //
//                                               ..',;:clollllodxkkOOOOOOOO0K0OOkkkxxddddddddxxxxxxxxxxxddollc:;,'...                                           //
//                                               ..'',:cclllllodxkkOOOOOOkOOOOOOkkkxxxkkkkkkkkkkkkkkkkxxxddolc:;;,...                                           //
//                                                ...',;ccclllodxkOkkOOOOkkOOOOOOOOkOOOkkkkkOkOOkkkkkOkkkxxdolc:,'...                                           //
//                                                 ...'',;::cclodxkxxkkOOkOO0OOOOOOkkkkxxkkkkOOkO00OxOOkOkxdollc;,'...                                          //
//                                                   ...',;;:clodxxxxkOOOOOOOOOOOOkkxxxxxxkkkOxKWWWW0O0OOkkxdolc:;,,''...                                       //
//                                                  .'',,;::cclooddxxkkOkOOOOkkkkkkkkkkkkkkOO00KWWWWNXK0OOkxxolcc:;,,'...                                       //
//                                                ..',''',;::cclllodddkkdOkOOkOOkOkkkkOOOO0KKXNNNNWWWNNKOkkxdollc:;;,,...                                       //
//                                                ......',,;:ccllloooxkdokOxkOOOOOOO00KXNNNWWWWWWWWWWWNK0OOkxdllc:;;;;,'..                                      //
//                                                  ..',;::clllllllldxdoloxkkOO0KXXNNWWWWWWWWWWWWWWWWWWX0OOkxollc:;;;;,,'..                                     //
//                                               ....';:cclllloddxkxxxxxxxxkO0KNNNWWWWWWWWWWWWWWWWWWWWWN0OOkxdllcc:;;;,,'..                                     //
//                                              .',''',;:clodkkkxxddooodxxkOOKNWWNWWWWWWWWWWWWWWWWWWWWWN0OOkxdolc::;;,,'...                                     //
//                                              .,;,,'';codddxddooooodddxkkkO0XWWWWWWWWWWWWWWWWWWWWWWWWX0Okkxollc:;;,'...                                       //
//                                              .,cll:;:loodddddooooooodxkkkkOKNWWWWWWWWWWWWWWWWWWWWWWNKOOkxdl::;,,...                                          //
//                                               .;c,,;:looddddooddoooodxxkkOOO0XNNWWWWWWWWWWWWWWWWWWWN0Okkdoc;,''..                                            //
//                                               ..',;;:cllodddddddddddxkkkO0KKXNNWWWWWWWWWWWWWWWWWWWWX0OOxdl:;,...                                             //
//                                                 .',;;:clodxxxxxxxxxkkOO0XXNNWWWWWWWWWWWWWWWWWWWWWWWXOxxdo:,'.                                                //
//                                                 ..',;:clodxkkkkkkkkOOO0XNNNWWWWWWWWWWWWWWWWWWWWWWWWNK00kl'....                                               //
//                                                  ..',:clodxkkkOOkkkkOOOO0KXXNWWWWWWWWWWWWWWWWWWNWMMWNKkdc;'''.                                               //
//                                                   ..';:clodxxkkkkkkkkOOOOOOOKNWWWWWWWWWWWWWWWWWWNWWXOdl:,'....                                               //
//                                                     .',;cllodxxxkkkkkOOOOOOk0XNNWWWWWWWWWWWWWWWWNWXxddc,..                                                   //
//                                                     ..'';:cooddxxxxkxxkOkkOO0KKKXKKXNWWWWWWWWWWNXKkxdc'.                                                     //
//                                                      ...,,:cooddxxkkx0XNXOxOOOO0KKKXNWWWNNWWWWWX0kxo:,.                                                      //
//                                                        ..',:odxdxkkkdOKK0kk0OKKXNNNNNNNNNWWWWWK0kdo:'.                                                       //
//                                                         ..',:looxkxkkxkkkkOOKNNNWWWWWWWWWWWWNKOkxoc,.                                                        //
//                                                         ....,;codxxxkOOOOOO0KXNNWWWWWWWWWWWNX0Okdl;..                                                        //
//                                                          ....,;clodxkkOOOOO0KXNNNWWWWWWWWWWNKOOkdc'.                                                         //
//                                                             ...,:codxkkOOOO0XNNNWWWWWWWWWNNK0OOkoc'.                                                         //
//                                                ..            ..';codxkkkOOO0KXXXNNNNNNNNNNX0OOOxo:'                                                          //
//                                                             ...,:lodxkkkOOOOO0000KXXNNNNNNXK0OOxl;..                                                         //
//                                                  .        ....';codxkkkOOOOOOO0O0KNNNNNNWWNK0Okxl,..                                                         //
//                                                  ..     .....';:ldxkkOOOOOOOOOOO0NWNNNNNNWNKOOkdl,..                                                         //
//                                                   .   ...',,';clodxkOOOOOOOOO000KNWWNNNNWWN0OOkdc,...                                                        //
//                                                  ..   .''',;;cloxxkkOOOOOOOOO00KNNWWWWWWWNX0OOkdc;'..                                                        //
//                                                    ...',,,,;:lodkOkkOOOOOOOOOKKXNNWWWWWNWNK0OOkdl;,..                                                        //
//                     ......                         ...,,,,,;:loxkk0000KK0kO0O0KXNWWNNWWWWNK0OOkdc,''.                                                        //
//               ...',;;:::::;'...                     ...'''',;coox0XOkxk0X0x000NXNWWWNNNNXK0OOOkdc,'..                                                        //
//             ..;:cccclllllllcc:;'.                    ....''',::lx0KOxkOKXOk00KXNNWNNXK0000OOOkxoc,'..                                                        //
//          ..,;clcllllloooollllcc:;.        .       ...',;::ccccclodkOOOkkkkOOO00KKXK0OOOOOOOOOkxo:,'..                    ..            .  .                  //
//         .,:lolclolooooooooollllc:;.      ..       .'';:lodxxxxddddddddddxxxkOOOOOOOkkkkOOOOkkxdlc;''..                   .,,'..        ..';,'..              //
//       .';:c:cclooooooooooolllllcc;.      ...      .',;coxkOOOOOkxxxxxdoddxxxxkkkkkkxxxkkkkkkkxxol:,,''.                   .,;;;.       ..';ccc:,'...         //
//      .':ccllccodooooooooooollllcc;.     .',.     ..',;cldkOOOOOkkkkkxdoddxxxxxxxxkkkkkkkkkkkkkkxoc;;,,..                   .;lc,,,... . ..';cclc:;,'..       //
//     .';cccloddddooooooooooollccc:;.     .',.     ..'';:cldxkkkkkOOkkkxdddddxxkkkkkkkOOkkkkkkkkkdlc::,,'.                    .llllllcc:;;','';clccc:;;'..     //
//    .';:ccllldxxxoododdddooolccc::,.     .',.      .'',,;clodxxxkkkOkkkxdddddxkkkkOOOOOOOkkxxkxooool:,,'.                    .':coolollolllcc:ccccccc:,,..    //
//    ';:cclllloxdxxdddddddoollccccc'.     .,,'.     ..''',:cloddxxkkOOkkkkkxddddddxkkxxxxxxddddddxkxoc,''.                      .::cllllllolllolccc:cll::;.    //
//    ,:cccllooodooddddddddoollccll;..    ..','.     ..''',;:looddxxkkkOOkOkkkkkkkkOO00OkxkkOkkkkOkOxoc,''.                   ..   .'clcllolollollllclolllc;    //
//    ;ccccllooodooddxxddddooollllc,''.   ..',,.      .''',;:loodxxkkkOOOOOOkkkOOOOO0000OOOOOOOOOOkkxol;''.                   .c'    ,ooooooooooloddooooolll    //
//    ;cccclooooooxxxxxxxddoooooolc;'..   ..';,.     ..'''',:loodxkkOOOOOOOOkkOOOOOOOOOOOOOOOOOOOOkxxdl:,'.                    ;o.  ..coodddddddddxkkxdooooo    //
//    :ccccllooodddddxxxxddoooolool:,.    ..,;,.      .'',,,:lodxxkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOkOkkxdoc,,'        ..          .oc;;...:oxxkkxkkkkkOOOkdoddo    //
//    cccclllooddddxxxxxxdoooodoloolcc,    .,,,.      .',,,,:lodxkkOOOOOOOOOOOOOOOOOO00OOOO0OO0OOOOkkkllo,.        ..',.        ;:cl,..'cxkOOkOOOOOO000Oxddd    //
//    cccclloooddddxxxxxxdooooddoodol:.   ..,,'.      .',,,;:ldxkkOOOOOOOOOOOOOOOOO000000000000000k0kdOd'':.          .'         .coc:.';okO00000KK00KKKOxdd    //
//    lllllcododddddxxxxddooodddoooo:'.    .',,.      .',,,;:ldxkkOOOOOOOOOOO00OOOO0000000000K00KOK0xXk':Ol           .,.         :olo;',lk00000KKKK0KKK0kdx    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DCLAIR is ERC721Creator {
    constructor() ERC721Creator("Diana Sinclair", "DCLAIR") {}
}
