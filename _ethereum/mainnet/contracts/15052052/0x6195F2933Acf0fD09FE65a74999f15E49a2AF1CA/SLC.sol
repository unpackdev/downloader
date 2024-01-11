
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sarah Lyndsay
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    lllllooooooooodddddddxxxxkkkkkkOOOO00KKKKXXKKKK00OOkkkkkkkkkkkkkkOOO000KKKKKK0000000000KKKKKXXXXKKKKK000OOOOkkkkxxxxxxxx    //
//    oooooooooooddddddddxxxxxxkkkkkkkOOO000KKKKKKK000OOOOOkkkkkkOOOOO0000KKKKXXXKKK00000000KKKKKKKKKKKKK0000000OOOOOOOOOOOOOO    //
//    oooooddddddddddddxxxxxxkkkkkkkkkkOOOO000000000000000000000KKKKXXXXXXNNNNNNNXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKKKKKXXX    //
//    ddddddddxxxxxxxxxxxxxkkkkkkkkkkkOOOOOO00000KKKKKXXXXXXXNNNNNWWWWWWWWWWMWWWWWWWNNNNNNNNNNNXXXXXXXXXXXXNNNNNNNNNNNNNNNWWWW    //
//    xxxxxxxxxxxxkkkkkkkkkkkkkOOOOOOOOO000000KKKKXXXNNNNNWWWWMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWNNNNNNNNNNNNNNNNWWWWWWWWWWWWMMMMM    //
//    xxkkkkkkkkkkkkkkkkOOOOOOOOOOO0000000KKKKKXXXXNNNNWWWWWWMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWNNNNNNNNNNNNNNNNNNNNNWWWWWWWWWWWW    //
//    kkkkkkkkkkkOOOOOOOOOOOO000000000000KKKKKKXXXXNNNNNNNWWWWWWWMMMMMMMMWWWWWWNNNNNNNNNNNNNNNNNNXXXXXXXXXXXXXNNNNNNNNWWWNNNNN    //
//    kkkkkkkkkkOOOOOOOOOOOO0000000000000KKKKKKKXXXXXNNNNNNNNNNWWWWWWWWWWNNNNNNNNNNNNNNNXXXXXXXXXXXKKKKKKKKXXXXXXXXNNNNNNNXXXX    //
//    kkkkkkOOOOOOOOOOOOOOO0000000000000000KKKKKKKXXXXXXXXXXNNNNNNNWWWNNNNNNNNNNNNNNNNNNNNNNXXXXXKKKKKKKKKKKKKKKXXXXXXXXXXXXXK    //
//    OOOO000000000000000000000000000000000KKKKKKKKKXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXXXXXKKKKKKKKKKKKKKXXXXXNNNNNX    //
//    0000KKKKKKKKK00000000000000000000KKKKKKKKKKKKKKXXXXXXXXXXNNXXXXXXXXXXXXXXXXXXXXXNNNNNNNNNNNNNXXXXXXXXXXXXXXXNNNNWWWWWWWW    //
//    00KKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXXXXXNNNNNNNNNNNNNWWWWWWWWNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXNNNNNNNNNNNNNNNNNNNNNN    //
//    000KKKKKKKXXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNNNNNXXXXXXXXXXXXXXXKKKKKKKKKK    //
//    0000KKKKKKXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNNNXXXXXXKKKKKKKKKKXXXXXXXXKKKK0    //
//    0000KKKKKKKXXXXXXXXXXXNNNNNNNNNNNNNNNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNNNNXXXXXKKK00OO0KXNNNWWWWWWWWNX0Okk    //
//    O0000KKKKKKKXXXXXXXXXXXNNNNNNNNNNNNNNNNNWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNNWWWNNNNNNNNNNNNNXXK00OkkkxxxddxkkOOOO0OOOOkkxdddd    //
//    OOOO00KKKKKKKXXXXXXXXXXNNNNNNNNNNNNNNNNWWWWWWWNNNNNNNNNNNNNNNNNNXXXXXXXXXXXXXXXXXKKK00OOkxxddddddddddddddddddddddddddddd    //
//    kOOOOO000KKKKXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXXXXNNNXXXXKxllodk0K000OOOOOkkkxxdddddddddddddddddddoooodxxxddddd    //
//    kOOOOOOOOO000KKKKXXXXXXXXNNNNNNNNNNNNNNXXXXXXXXNNNNNNNNNNNNNNNNNNXd.....'oKXXXXXKKKK0OOOkkkkkkkkxkkkkkkkkxxxxxkkOOOOkkxd    //
//    kkOOOOOOOOO000000KKKKKXXXXXXXXKKKKKKK0OOkkkkkkOO0KKXNNWNNNWWWNNNN0:.    .'xXNNNXXXNNNNNNNNNNNNXXXXNNNNNNNNNXXXXNNXXXXK00    //
//    kkkOOOOOOOOO00000000000000000OOOOOOOkkkxxdddddxxxxxxkOKXNNNNNNNNXd.      .:0NNWNNWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMWWWWWWWN    //
//    kkkOOOOOOOOOOOOOO000000OOOOOOOOOOOkkkkxxxdddxxxxdddddddkOKXNNNNNO;        'dKXXXKXKKKXXXXXXXXNNNNNNNNNNNNWWWWWWWWWWNNNNN    //
//    kkkOOOOOOOOOOO000000000OOOOOOOOOOkkkkkxxxxxxxxxxdddddddoodk0KKXXx'  .     .lOOOOkkkkkOO0000KKKKKK00KKKKKKXXXXXXXXXXXXXXX    //
//    kkkOOOOOOOOOOO000000000000000OOOOOkkkkkkkkkkkkxxxdddddxdddddxxkOd. .;.    .:OKKKK0KKKKXNNNNNNNXXK00OOOOOOOkkOO0000000OkO    //
//    kkkOOOOOOOOOO0000000000000000000OOOkkkkkkkkkkkxxxdddddxxxxkkOO0Ol..:c.     'xXNNNNNNNNWWNWWWWWWNNNXXXXKK00OOO00KK00Oxxod    //
//    kkOOOOOOOOOO000000000KKKKKKKKK000OOOkkkkkkkkkkkxxxxddddxkkOKXXXKc'cl:.     'xXNNNNXXXXXXXXNNNNNNNNNXXXXXXKKKKK00O0Odlccc    //
//    kkOOOOOOOO0000000KKKKKKKKKKKKKKK00OOkkkkkkkkkOOkkkxxxkkO0KXNNNN0ocl:'.     .dKXXXXXKKKKKKKXXXXXXXXXXXXXKKKKK00xdxdoc::::    //
//    kkOOOOOOO00000000KKKKKKKKKKKKKKK000OOOOkkkkOOOOOOOOO00K0xdk0K0Oxoc;'...    .lO0K00000000000000KKKK0000000000Odccc;;;;;,,    //
//    kkkOOOOO00000000KKKKKKKKKKKKK0000KK000000000KKKKKKKXXXN0ddxxxxxdl:,.''..   .:xkkxxxxxkkkOOOOO00000OOOOOOOOkdo:;;;,,,,,,,    //
//    kkkOOOOO00000000KKKKKKKKKKKKK00000KKKKKKKKKXXXXXXXXXNX0kxolllloxkxocc:,..  .:kOkxxxxxxkkkxxkkkOOOOOOOOOkkxl:;;,,,,''''',    //
//    kkkOOOOO0000000KKKKKKKKK000000000000000KKKKKXXXXXXXXX0dloolllc;:lddddlc;....lOKKKKK00OOOkkxxxxkkOOOOOOOxl:,,,,,'''''''',    //
//    kkkOOOOO0000000KKKKKKKKK000OOOOOOOOOOOO00KKKXXXXNNNKkl:;clollc:;;:cllddo:,,cx0KXNXXXXKK000OOOOOOOOOOOko:;'''''''''''''',    //
//    kkkOOOOOOO00000KKKKKKKKK000OOOOOOOOOO00KKXXXNNNNNN0xc,'':ldolc;;;,;;:clooc:cccldkOKXXXXKKKKK0000OOOkxl;,''''''...'''''''    //
//    kkkkOOOOOOO00000KKKKKKKK000000OOOOO00KKXXXNNNNNNKko:'..':ldxxo:;;;;,,,'''.....',:ldO0KKKKKK00OOOkkdl:,''''.........'''''    //
//    kkkkkOOOOOO00000KKKKKKKK000000OOOOOO0KKXXXXXNXKOdl:,....;lokOkdlcc;,'........'',;:codxO0K000OOkkdc;''..............'''''    //
//    kkkkkkOOOOO00000KKKKKK00000000OOOOOO000KKKK0Okkdc;,.....;ddxO00xl;.........''',,,,;;:coxOkxxkOkxl,.................'''''    //
//    kkkkkkOOOOO0000000000000000000OOOOOOOOO00Odl:;;'........,okkOOOd:..  ..........''''',;:lxxl:lo:;,....................'''    //
//    kkkkkkkOOOOOO00000000000000OOOOOOOOOOOkxl:,'''......'....,:ccc;,....................',;:oo,.'..........................'    //
//    kkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOkkkkxo:,'........'''.................'..............',;::,.....,::;;,,'................'    //
//    xxxxxxxxkkkkkkkkkkkkkkkkxxkkkkkkxxdl,................................'''''''',''....',;;;'....,c:;;;;::;,..............'    //
//    xxxxxxxxxxxxxkkkkxxxxxxdddddddxdol:...................''.''''..'''....''...'''''''',,'.','.''.,:::;,,;ccc;,'............    //
//    dddddddddxxxxxxxxxdddddooolcc::;;,'.............................'''....''''.''''''',,,'.......','.''',,::,,,,,'.........    //
//    oooooddddddddddddddoooollc;,''''''..............................,,',...'',,,,,,,,,,,,;:,..  .........''',,'',;;,'.......    //
//    looooooddddddddoooolllc:;,'''.''................................''''.....',;;,,,'',''',,,'.. ........''.'''''',;:;'.....    //
//    llllooooooooooollllcc:,''''..............................'......''.........',,,''...'''..';,...  ....''........';::,....    //
//    lllllllooooollllccc:;,'.''...'''....................''..'''.................,,'','.'.....,,''.    .............',;c:,...    //
//    ccclllllllllcccc:::;''..''''''''.......................................... ..''',,'........''...............''..'',:;'..    //
//    ccccccccccccc:;;;,,.........''''.................'''....................... ........................................,,..    //
//    :::::ccccc:::;'...............'.............................................   .....  ......  ...  .....................    //
//    :::::::::::;,'. ........''.................''....'..................... ....      ..  .....          ............  .....    //
//    ;;;;::::;;;,'..........'''..'''........................................ .....                        ..    ...              //
//    ;;;;;;;;;,'...''........''..''.....  ................   .......................                      ...  ..                //
//    ;;;;,,,,'.......  ......'............................   .............'..... .                         ... ....              //
//    ,,,,,'.........  ....................................   ...............                                    .....            //
//    '......          ...................................    ..........                                          .....   .       //
//    .........         ..................................   ..  .....                   ..........                ..........     //
//    .......''..      ........    ...   ................    .                  ...    .............                 .''......    //
//    ...''......      .....             .  ............                      ......  .......  .......               ...'.....    //
//    ..........      ....                  ............                  .........  .........  .......              ........     //
//     .........      ..                   .... .. ..                   .......  ..  ...................             .. ...       //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SLC is ERC721Creator {
    constructor() ERC721Creator("Sarah Lyndsay", "SLC") {}
}
