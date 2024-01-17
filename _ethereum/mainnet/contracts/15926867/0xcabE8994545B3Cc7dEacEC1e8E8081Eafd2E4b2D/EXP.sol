
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: [ THE EXPERIMENT ]
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                  .............................................................................'''''''..........                //
//     .............'',,,;;:ccllllllllllllllllooooolclllooddxxddddddoodooooooooddddooooooolllllloodddollcc:;;,,''.......          //
//    .........',,,;::clloodxxxkkkkOOOOOOOOOOOOOO0OOOOOOO0000000000000000OOOOOOOO0OOOOOOOOOkkkkkkkkkkkxxddoollcc:;,'.........     //
//    ....''',;::ccllodxxkkOOO0000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0000000000000000000000OOOOOOOkkkxxddddol:;'........     //
//    .'',,,;:clooodxxkOO00000KKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKK000000000OOOOkkkxxxdoc;,,'......    //
//    ',,;::clodxxxkkOO000KKKKXXXXXXXXXXXXXXNNNNNNNNNXXXXXXXXNNXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKK00000000OOOOkkkxdoc:;,,'''..    //
//    ;::lloodxkkOOO000KKKKKXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXXXKKKKKXXXXXXXXXKKKKKKKKKK00000000OOOOkkkxdlcc:;;,,,.    //
//    :lldxxxkOOO0000KKKXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXXXXXXXXXXXXXXXXKKKKKKKKK000000000OOOOkkkxdoolc::;;'    //
//    :ooxkkOO0000KKKKXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXXXXXXXXXXXXXXXKKKKKKKKKK000000000OOOOkkxdddollcc:,    //
//    codkkOO000KKKKXXXXXXXXNNNNNNNNNNNNNNNNNNNNWWWNNNNNWWNNNNNNNNNNNNNNNXXXXXXXXXXXXXXXXXXKKKKKKKK00000000000OOOOkkxxxdoollc:    //
//    cdxkOO000KKKKXXXXXXXNNNNNNNNNNNNNNNNNNNNNWWWWWWWWWWWWNNNNNNNNNNNNNNNXXXXXXXXXXXXXXXXXXKKKKKKKKK000KKK0000OOOOkkxxxddoooc    //
//    lxkOO00KKKKKXXXXXXNNNNNNNNNNNNNNNNNNNNNNWWWWWWWWWWWWWWWWWNNNNNNNNNNNNNNNNNNNNNNXXXXXXXKKKKKKKKKKKKKKKK00000OOOkkkxxdddoc    //
//    lxkO00KKKKKXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNWWWWWWWWWWWWWWWWNNNNNNNNNNNNNNNNNNNNNNNNXXXXXXKKKKKKKKKKKKKKKK000000OOkkkxxxxdc    //
//    lxkO00KKKKKXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNWWWWWWWWWWWWWWWNNNNNNNNNNNNNNNNNNNNNNNNNXXXXXKKKKKKKKKKKKKKKKKK00000OOkkkkxxxl    //
//    lxkO00KKKKKXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNWWWWWWWNNNNNNNXK0kkOKNNNNNNNNNNNNNNNNNNXXXXXKKKKKKKKKKKKKKKKKKKKK000OOOkkkkkxl    //
//    lxkO00KKKKKXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNWWWWNNNNNXX0xlc:clxO0KXNNNNNNNNNNNNNNNXXXXKKKKKKKKKKKKKKKKKKKKKK00OOOkkkkkkc    //
//    lkkO0KKKKKXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNWNWNNNXXXKK0xc;,;;;;;cox0KXNNNNNNNNNNNXXXXXKKKKKKKKKKKKKKKKKKKKK000OOkkkkkxc    //
//    lkOO00KKKKXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXKK0kdoll;''''....',;oOXNNNNNNNNNNNXXXXXKKXXKKKKKKKKKKKKKKKK00OOOkkkkkx:    //
//    lkO000KKKKXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXOxdol:,,,;,'.........',lOKXNNNNNNNNNNXXXXXXXXXXKKKKKKKKKKKKKK00OOOOkkkkx:    //
//    lxO000KKKXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNX0dl::;;;;;;;,''''.......;oOXNNNNNNNNNNXXXXXXXXXXKKKKKKKKKKKKK00OOOOOkkOkx:    //
//    cxO00KKKKXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNXOdc:;;:::::::,''''.....'ckKXNNNNNNNNNNNNXXXXXXXXXKKKKKKKKKKKKKK0OOOOOkkkkx:    //
//    :xO000KKKXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNKx:;;;;:::;;;,,,,''.....,lkXNNNNNNNNNNNNNNXXXXXXXXKKKKKKKKKKKKKK00OOOOkkkkd;    //
//    ;dkO00KKKKXXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNN0d:::lllc:;,,,''''........:x0KXNNNNNNNNNNNXXXXXXXKKKKKKKKKKKKKKK0OOOOkkkxxd;    //
//    ;oxO000KKKKXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNX0kxdddoc;,'''..............;lkKXNNNNNNNNNXXXXXXKKKKKKKKK0KKKKKK0OOOOkkkxxd:    //
//    :oxO0000KKKKKXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNXOxocccc:;'....................,d0XXNNNXXXXXXXXKKKKKKKKKK000KKKKK0OOOOkkkkkd:    //
//    :dxkO000KKKKKXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNKd:,....................      ..'lkKXXXXXXXXXXXXKKKKKKKK0000KKKK00OOOOkkkkkd:    //
//    :oxkO000KKKKKXXXXXXXXXNNNNNNNNNNNNNNNNNNNNXk:................             .,oOKXXXXXXXXXXXXKKKKKKKK0000KKKKK0OOOOkkkkkd:    //
//    :odxOO0000KKKKXXXXXXXXXXXXXXNNNNNNNNNNNNNNXd'.                             ,xKXXXXXXXXXXXXKKKKKK0000000KKKK00OOOOkkOOkx:    //
//    :odxOO0000KKKXXXXXXXXXXXXXXXXXNNNNNNNNNNNNXx,                              .l0XXXXXXXXXXXXKKKKKKK00OOO0KKKK0OOOOOkkOOkx:    //
//    ldxkOO00KKKKKXXXXXXXXXXXXXXXXXXNNNNNNNNNNNNKk;.                             'dKXXXXXXXXXXXKKKKKKKK000O0KKKK0OO00OkkOOkx:    //
//    oxxkOO000KKKKKXXXXXXXXXXXXXXXXXXNNNNNNNNNNNNKo..                          .':xKXXXXXXXXXXXKKKKKKK000000KKKK0OOOOOkkkOkxc    //
//    dxkkOO000KKKKKXXXXXXXXXXXXXXXXXXXNNNNNNNNNNNX0Oxl.                   .'..,d0KKXXXXXXXXXXXXKKKKKKKK000000KKK0OOOOOkkkOkxc    //
//    dxkkO0000KKKKKKXXXXXXXXXXXXXXXXXXXNNNNNNNNNNNNXX0c......            .d00O0KXXXXXXXXXXXXXXXKKKKKKKK000000KKK0OOOOOkkkkkxc    //
//    odxkOOO00KKKKKKXXXXXXXXXXXXXXXXXXXXXXNNNNNXXNNNNX0xxOOOo'           'kKKKKKKKXXXXXXXXXXXXXKKKKKKKK000000KK00OOOOOkkkOkxc    //
//    oodxkOO000KKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXNXXXXXNNNNNXXX0c           .lO0KKKKKKKKXXXXXXXXXKKKKKKK00000000KK00OOOOOkkkkkxc    //
//    oodxkkkOO00KKKKKKKKXXXXKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0c            .:xO0KKKKKKKXXKKXXKKKKKK00000000000KK00OkOOOkkkOkxl    //
//    oddxxxxkO000KKKKKKKKKKKKKXKKXXXXXXXXXXXXXXXXXXXXXXKKKKOd,              .;okO00KKKKKKKKKKKKKKKKK000000O00K000OOOOOkkkkkxl    //
//    lodddxxkO00000KKKKKKKKKKKKKKKKXXXXXXXXXXXXXXXKKKKKK0Od:.                 .;cxkO00KKKKKKKKKKKKK00000OOO00K000OOOOOkkkkkxl    //
//    loddxxkkOO000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0ko:,..                    .'cok000000KKKKKKK00000OOOO000000OOOOOkkkkkxl    //
//    oddxxxkkOOO00000000KKKKKKKKKKKKKKKKKK000KKKKKKKOo,.                         ..,lk0000000000K0000000O00000000OOOOOkkkkxxc    //
//    odddxxkkkOOO0000000000KKKKKKKKKK000000000000Oxl;.                              .;lxOO0000000000000000OO0000OkkkOkkxxxxxc    //
//    looddxxkkkOOO00000000KKKKKK0KK0000OOOOkxdoc;,..                                  ..';coxO00000000000OOO0000Okkkkkkxxxxxc    //
//    cooodddxxxkOOOOO0000KKKKKK0000000Oxdlc,...                                            ..,lkO00000000OOOO000Okxkkkxxddddc    //
//    coooooddxxxkOOOOOOO000KKK000000Okd:...                                                   .:xOOOOOOOOOOOOOOOOkxxxkxdddooc    //
//    :looooddxxxxkOOOkkOO0000000O0OOkxc'.                                                      .lkOOOOOOkkkkkkkkxxdxxxddooooc    //
//    :llllooddxxxxkOOOOOOOO0000OOOOOkd,..                                                       'dkkkkkkkkxxxxxxxdodddoooollc    //
//    :lllloodxxxxkkkkOOOOOOOOOOOkkkkkc.                                                         .:xkkkkkkkxxxxxxddoooolllllc:    //
//    :lllloodddxxxkkkkkkkkkOOOOkkkkxd;.                                                          .okkkkkkkkxxxxxddoooolc::::;    //
//    ;ccllllooooddxkkkxxxkkkkkkkxxxxl.                                                           .;xkkkkkkkxxxxdddooolc:;::;,    //
//    ,::::cclllloddxxxxxkkkkkkkkxxxd:.                                                            .lkkkkkkxxxddddoolllc;;;;;,    //
//    ';;;;;:::cclooddddxxkkkkkkxdddo,.                                                            .,dkkxxxxdddddoollcc;,,,,,'    //
//    .,,,,;;:::cclooddddxxxxxxdolll:.       .                                                      .lxxxdddddoooolccc:,'''''.    //
//    .'''',;;;::ccloooodddxdddol:;;'.  .   .........  ..  ...                                      .;ddddddoollllc::;;'......    //
//    ......',,;;:ccllllooodddool:;,.. ........................                   .. .              .'ldddooolccc:;;,''.......    //
//    ........',,;;:cccccllooollc::;'.......,;;,,,;:,'......................     .........    .      .cooooolc:::;,,'.........    //
//     ........'',;;::::ccllllloollc:,',;:,;lddooodddlccccclllllllllc:;;,'.......',''''''.............:oloolc:;;;,,'..........    //
//     ..........'',,;;::ccllllodddddollooooxkkkkkkkkxxxxxxkkkkkkkkkxxdooc,.....':cccccc:::::::::ccc::cllllcc:;,,,'..........     //
//        .........',,;;:::cccclooddddooddddxkkkkkkkkkkkkkkkkkkkkkkkkxxddl;'''..,:llllclllllccccllllllcllllcc:,,,'.......         //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EXP is ERC721Creator {
    constructor() ERC721Creator("[ THE EXPERIMENT ]", "EXP") {}
}
