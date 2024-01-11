
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EMRGNC2
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                           ...............                                                      //
//                                                   ..',;:cclooddddddddooc:;,'..                                                 //
//                                               .';cldxxxxxdddddddddddddddddool:,'..                                             //
//                                            .;coxxxdddddddoooooooooolloooolooooolc,..                                           //
//                                         .'coddoddddddoooooddxxxxxdddddddoooollccc::;'.                                         //
//                                        .:ooooddddddollodxxxxxxxxxxxxxxxxxxxdddoolc:,,'.                                        //
//                                       'loloooddddollodxxxxxxxxxxxxxxxxxxxxxddddooolc:;,..                                      //
//                                      ,llllooddddddolldxxxxxxxxxxxxxxxxxxxxddddddooollcc:,.                                     //
//                                     .llcllooodddddddolddddxxxxxxxxxxxxxddddddddoooollcc::,.                                    //
//                                    .:l:cllooooodddddolldddddddddddddddddddddddoooolllccc:;'.                                   //
//                                    'c::clloooooooooooollodddddddddddddddddddoooooolllccc:;,..                                  //
//                                   .;c:cclllooooooooooolcldooclododdddddddddoooooolllccc::;;'.                                  //
//                                   .c::clllooooooooooooccool:clooooododddooooooollllcccc::;;,.                                  //
//                                  .:c:cllloooooooooooolclol::loooooooooooooooolllllccc:::;;,,..                                 //
//                                 .;c::cllloooooooooooollllc::ccllcccccllooloollllcccc:::;;;,'..                                 //
//                                 .:l;;:clllooooooooooooolllcccclollcclloollllllcccc::::;;;,''..                                 //
//                                  'c;,,;:cclllllooolllllooooooollcc:cccclllllccccc:::;;;,,,''.                                  //
//                                  .''...',;:ccllcccllcccccllollc::::cllcccccccc:::::;;;,,''''.                                  //
//                                  .,,'..',,;::;;:cloooooolllcccc:::cclolc::cc:::::;;;,,,''.',.                                  //
//                                ..;;;,'',;;:;,;:lllllollllllc:cccc::clllc:;:::::;;;,,,'''.',.                                   //
//                               .':::;,,,,;;,';cccllllllllllcccc::::;;;;:;,;;;;;;;,,,''.'.','.                                   //
//                              .,::::;,,,,;'.,::ccccccccccccc:c:::::;,'','...''''''''....',..                                    //
//                             .,:c::;,,,,,,'';::::cccccc::ccc:::;,,,'...............''.'''.                                      //
//                            .';:::::;,',,,'';;:::::cc:;;'';;'......'''''',,,,,,,,,,,''''.                                       //
//                            ..,,,,,;;,',,,..,;::::::::'.''''...........'',,'''''',,,'''.                                        //
//                             .....',,,',,,.',;;:::::::;'.','.....................',,','.                                        //
//                                 .',,,',,'',;;;;:::::::;,.......''..''.......',,;,,,',.                                         //
//                                 .,''''''.',;;;;;:::::::;.....,;;;;;;;;;,'....',;;,,,'.                                         //
//                                 ..'......,,,,;;;;;:::::,....,;;:::::::::;;'....''''''.                                         //
//                                  ..'''...',,,,,,;;;;;;;,....,;;::::::::::::;,'.....''.                                         //
//                                  ..''''...',,,,,,,,,,,,,'....,;;;::cccc::::::::;;,,,,.                                         //
//                                    .,'...''''''''''''''''.....',;:::::cc:::::::::;;;,.                                         //
//                                    .,..'''''''''''''''''.........,;;::::c:ccccc:::;;,.                                         //
//                                   .''.''''''''......................,;::::cccccc::;;;..                                        //
//                                    .,'..''..........................',,;;:cllcc:::;,,,.                                        //
//                                    ..',,,,,',;,,,'''...............,;::::cdOkoc,''...,'.                                       //
//                                      ....''',;::;,:o;.............';:::cccodl:,.....'''.                                       //
//                                                   .:l'....''.....,;::::c:;,'''.....',,''.                                      //
//                                                    .c;....''...',;:::::;'......''...''',,.                                     //
//                                                    .;c,..''...',,;;;;;'.....',,;'......';;.                                    //
//                                                     .';,':c,..,,,,,'.......',,;,'......,::;.                                   //
//                                                      ..;cdo;...............''',,'.....';::c;.                                  //
//                                                        ,oxd:...............''..:,.....,;;:::;.                                 //
//                                                        .:Ox:......'.......','..,'... .....';::.                                //
//                                                         'do........... ..,:'..             ..;;.                               //
//                                                          ;c'...........,,...                 .;;.                              //
//                                                          ';...........,'.                     .:.                              //
//                                                         .,,........','.                        ..                              //
//                                                         .:;,,',,,,,,..                                                         //
//                                                       .;llclclllc;..                                                           //
//                                                     .ckkxkkkxl;'..                                                             //
//                                                    .oOkOK0dc'.                                                                 //
//                                                    ;xkOkc'.                                                                    //
//                                                   .;oo;.                                                                       //
//                                                   .....                                                                        //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EMRGC is ERC721Creator {
    constructor() ERC721Creator("EMRGNC2", "EMRGC") {}
}
