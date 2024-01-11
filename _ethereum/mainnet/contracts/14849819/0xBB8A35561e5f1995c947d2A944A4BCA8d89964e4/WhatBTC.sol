
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: What if I bought BTC
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                             ..                                                                                                 //
//                             .. ''                                                                                              //
//                             .  'c;,'....                                                                                       //
//                            ..  .:c:ccccc::;;,,,'..                                                                             //
//                            ..  'lc:ccccccllllcccc:;,,''.....                                                                   //
//                            ..  .do:cccccclllccccccc:::::::::;;,,,'..                        ....'..  .......                   //
//                            .   .dkc:ccccclloddolccccccc:ccccllooddddol:;..            ..;codkO000kdodolllc;,'.                 //
//                           ..    dKo:cccccllodxxxxddollccc::ccloddxkkkOOOkdc:;'.'',;:ldOKXNNNNXK0OOOkdllodxxddc.                //
//                           ..    lXxcccclcclodddxxkOOOkkxdolccccllllodxkOOOOOOxolcc:codxOOOkxolccccc::cloodxkOko;.              //
//                           ..    cXOlccllcllloddddxkkOO0000OkxddddddddddxxkO00OOOkdol:;;;;;;;:::::::::;;;:coxxxdl;.             //
//                           .     cX0occclllllldxddkOOOOOO000000OOOkxxxxxxxxkOO00Okxdddddolc:::::::::::::c:cdxxkkxo;.            //
//                          ..     lNOolcllllooloddxO00000KKKK00OOOOOOkkkkkkkOOOOOOOkxxxk000OkxdooloooooodddxkOkkOOd:;.           //
//                          ..     oNOolcllookOollok000KKKKKKKKK0OkkkxdxO00OOOOOkkkkOO0000000KKK0000000000KKKKKKKXXOc;'           //
//                          ..     dNklollddd0Oocld0K0KKKKKKKKKKK0Oxdollk0K00000OOOkOOOOOOOOO000KKXXXXXXXXXXNNNNNNNOc;.           //
//                          ..    .kNklllxkdkKklcld0K00KKKKKKKKKX0kdlccldOKKKKK0000000000OkkkOOO0KXNNNNNNNNNNNNNNXOl:;.           //
//                         ..     'OXxdodOkx0Oollok0000KKKXXXXXXKxolccllokKKKKKKKKKKKKKK00OxxxxxxOXNNNNNWNNNNNNKkl:;;,.           //
//                         ..     ,KKkxodkx0KxclxOO0KKKKXXXXXXX0xlcllcllokKKKKKKKKKKXXKKK0kdooodxKNWWWWNNNNNX0dc:;;;;'.           //
//                         ..     lXKkdlodOXklldO0O0KKKXXXXXX0kocccccllodOKKKKKKXXXXXXXXKOdooookKNNNWWWNXK0xl:;;;,,,,'            //
//                         ..    .xXOdlloOKOollkK0O0KXXNNXKOxoccccccllodOKKKKKXXXXXXXKOkdolodkKNNNXXK0Oxdl:;;;;;;;;;;,.           //
//                         .     'kkolloOKklclx000KXNNXKOxolcccccclllox0KKKXXXXXXKOkxooodkOKXNKOxdollc:;;;;;;::::::::;.           //
//                        ..     'lclldOKxllok0KXXNXKOxolc:::ccclllodkKXXXXXKOkxdoodxO0KXXX0kdlc::::::;::::cccccccccc;.           //
//                        ..     ':cok0OdlldOXNXX0kdoc:::::cclloxkO0KK00Okxdoooxk0KXXXKOkdl:::::::::ccclodxxxxkkxolcc,.           //
//                        ..    .cldOOdllxOXXKOxolc:::::clodxxkkkkxxdoolodxkO0KK0Okxoc::::ccloooddoodxdxxxxkkkkOkocc;'.           //
//                        .    .;lxOdlok0K0kdlc:::::cloddddddooooddxxkOOOkkxdollcccloodxxxxxxdodxdloolccllodxxkxo:;,'.            //
//                        .    ';coloxkkdlc:::::cccloddddxxxxkkkkxxxddollllodxxkkkxxxdoollcc:cclccccccclooodkkd:,'...             //
//                       ..   .;;:lool::::ccllooddddxxxxxxdddoooodddxxxkkkkkkxxdolccclllllllcccccllloddxxdoxko,',,'.              //
//                       ..  .,;;::::clooddddxxxxxxxxxxxxxkkkkOOkkkkkxxddoooooddddxxxkkkOOOOOOOO000KXXXXK0Okd:'.'....             //
//                       .   .....',,;:ccllooddddxxxxxxxxxdxxxxkkkxxxxxxxxxxxxxxxxddddxddoooooodddoolc::;;,'',,,,;;;,.            //
//                       .                                   ...............                                   ...'..             //
//                       .   .                                                                                                    //
//                      ..    ...                                                                                                 //
//                      ..             . .                                                                                        //
//                      .                                                                                                         //
//                      .                                                                                                         //
//                      .                                                                                                         //
//                     ..                                                                                                         //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WhatBTC is ERC721Creator {
    constructor() ERC721Creator("What if I bought BTC", "WhatBTC") {}
}
