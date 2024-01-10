
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Luminosem
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                   ....                .lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                            ....................        .lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                        ............................     .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                   ......................''............   'kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//              .......................''',,,,,,,,'''........:KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//         .....................'''''',,,;;:ccccc:;;,'.......'xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    .......................'',,''',,;;:clodxxdooc:;,,''''''.:KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    .....................''',,,,;;;:cloxkkOOOkkdolc:;;;;;;,''dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    ...............'''''',,,,;;::clodxkO00000Okxdooollccc:;'.;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    ..........''''',,,,;;;;;::cclodxO0KKKKK00OOkxxxxdoolc:,'..lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    ''.'''''',,,,,;;;;:::::cllodxkO0KKKKK0000OOkkkkxxdooc;,'..'kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    ''',,,,,;;;;::::ccccllooddxkO0KKKKK00000OOOOkkkxdoll:;''...;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    ,,;;;;;::::ccclllooooddxxkO00KKKK0000OOOOOOkkxxdocc:;,'.....lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    ;::::::cccclllooddddxxxkkO0KKK0000OOOOOOkkxxddolc:;;,''......:xKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    :::::cccclllloodddxxxkkO0KKK000OOOOOOkkxxddooolc:;;,,''.........;oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    ;;;::::ccllloodddxxkO00KKK000OOOOOkkkxxxdooollc::;;,,''.......    .'lkNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    :::ccccllodddxxkkO00KKK00OOOOkkkkkkxxdddooollcc::;;,,,'.......        'cONMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    kOOOOO00KKXXXXXXXKKK0OOkkkkkkkxxxdddoooolllllcc::;;;,,'.......           ,oKWMMMMMMMMMMMMMMMMMMMMMMM    //
//    looolooodxxO0XNNXK00Okkxxxxxxdddolccclllllllcc:::;;,,''.......             .:kNMMMMMMMMMMMMMMMMMMMMM    //
//              ...';lxO0Okkxdddoooolc::::::cccclccc:::;;,,''........               'o0WMMMMMMMMMMMMMMMMMM    //
//                    .'cdkkdddoolc:;;,,,,;;::ccccccc::;;;,''........                 .:xKWMMMMMMMMMMMMMMM    //
//                      ..;lddolc;,'''''',,,;;;::::ccc:;;;;,''........                   .:dOXWMMMMMMMMMMM    //
//                        ..,clc;,''....'''',,,;;;::ccc:::;;,,''........                    ..:oONMMMMMMMM    //
//                          ..',;,''......''''',,;;;::ccc:::;;,,'..........                      'lONMMMMM    //
//                             ...'''.......''''',,;;:ccclccc::;,'...........                      .:kNMMM    //
//                              ......''''....'''',,;:ccllllllc:;,''.............                    .:kNM    //
//                                ......''''''''''',,;:clloooolc:;,,''...............                  .:k    //
//                                  ......''''''''',,;:clloddoollc:;,,''.......................          .    //
//                                   .......'''''''',;:cllddddddolcc:;;,,'''''.....................           //
//                                    ........',,,,,,;:lloxxkkxxddolcc:;;,,',,''''''.......''''''.....        //
//                                      .......',,;;;:coodkOOOOkkxddolc::;;;;;;,,,,,,,,,,,,;;:::;;,'.....     //
//                                       ........,:ccloxxkO0000OOkkxdoolcccccc:::;;;::;;;::clooollc:,'....    //
//                                     ...........,codkO00KKK00OOkkkxxxxxxddooolllcccccccclodxkkkxdoc:,'..    //
//                                      ...........'cxOO0000000OOkkkOOO00OOOkkkxdolcccccccldxOO00Okxdoc:;,    //
//                                      .............;okkkOOO000OOOO0KKKKKKKK0Oxoc:;;;,,;;:cokO00000Okkxdo    //
//                                       .............'cdxOO00KKKKKKKKXXXNNX0koc:,''......',:oO0KKXXXXXXXK    //
//                                       ...............'ckKXXXNNNNNXXNNNNX0dl:,'...........':xKXNNNWWNNNN    //
//                                     .   ...............cKWWWMMWWWWWNWWWKkl:,.............',oKWWMMMMMWWW    //
//                                     ....................lXMMMMMMMMMWMWNOdc;'.............';xXMMMMNXNMMM    //
//                                      ....................lXMMMMMMMMMMWXOxl:,,''.........',oXMMMMNx;:kWM    //
//                                    .......................oNMMMMMMMMMMMWNK0kxdolcc::::::cdKMMMMMW0o;c0M    //
//                                     ......................'xWMMMMMMMMMMMMMMMWWNNXXKK0000XWMMMMMMMMWXKXW    //
//                                     .......................;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                 .. .........................oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                      .......................,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                  ..  ........................lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                      ........................:0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                      .......................',kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                 .... ........................,dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                         ..      .............................'oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LUMI is ERC721Creator {
    constructor() ERC721Creator("Luminosem", "LUMI") {}
}
