// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: In Your Sleep Last Night 2
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//     ........................','........'::,'.,:;,,'.,,...........';;'......''''......   .',,,;::::::;......................    //
//    .....................,coxkkxl:;:;,cdOKXK0k0XK00OxOO:.......',',clc;'''',,'............'''.,::::;;,......   .............    //
//    ......  ........''..cxO00OOOOkxxkO0KKXXXXXXXXKKKXXXOooddoc:cc::ccclc:;;,,,'..........',,,,;:::::,........ ..............    //
//    ......... .....',,,ckOOkkkO0KX00XXKKXXXKXXXXXXXXXKKKKXK0OOdodocclloddolc:;,,,.........';;;;:::;,..........  ...........'    //
//    ......... ....',,,,cxxxxkOO0KKKKKXXXXKK0K0KKXXXKKK000000OkddxdodxdddoooxOkdlcc;............',,'.. ........  ..........''    //
//    ....'....  ...,,;lolodk0XXKKKKKKXXKKKKKKKKKXXKK0kxdxxkkkxdlodddxkkxxxdodxkkkkkxdl:,.. ........... ......... .........'',    //
//    ..............'':dxxx0XXXXXKK00KKKKKKXXK0000OOOxolc:::oxxxxxkdodkOOOkxxxkkxxddddxxdoc,.......'''........................    //
//    ............;llloddddk0KK00KK0OO00000KK0kxxxdddolcclol:coxkO00OkOO0K0kkkkxxdooollcc:;;;;;,'..,::c:,,'...................    //
//    ............,xOkxdddddk0K0O0KKOkkOOkxxkdloxdolllc:clolc:;:lxkO00000000Okxxxdoccclc:;,;:;,,'..',,,'',,'..................    //
//    ...........,lxkxxddkkxkKKOxdxkOOxxOkkOOolxo:...'''clc:codolloodkO0OkkOOOkkxxdollllc:;;;'''.'',,,'',;;,,'................    //
//    ......   .,oddxxxddOOxxk0KOc..'::;cx00Kd....    .,loolloooolllccccloxxkdddoodddddolc;,,,,,,,'........''.................    //
//    ...'... ..lxxkxxdddkkkxddkOd;.     ...',. ...... 'ldddolllllllodl:clooolloooollooodol:,::;'.........''..................    //
//    .........:oddddddxxkO0OxxOOl;:' .',,....'',;:cc:,',colllllloooolooollooxdlcccllcclolccc;,'...............'..............    //
//    .. .....'coloddoododkOkdoxx:... ,llcc;,;cldkOOkdl:,;lc:cllloolllll:;:c:;;;codoooc:cc:cc;,,,..............'..............    //
//    .........':lodxdooodkkxdddc.    'oxxxdddxO0K0Oxdoc:odl:::ccllllllllccc,',,',,;;;;;::c:::cooo:,....'..........  .........    //
//    ..........;ooodxxxddxkkdc,.    .'lxkOOOO00KKKOxllloxxollloooodoolllcc:;,,.. ..'....'cxO00OOO0Oxl'............  .      ..    //
//    ....... ..':clclddodxdc.      .,cllxOKKKKKKKK0kd:;:cclooooodddooolcc;;;,'....  ...;dOKK0Okxxdddl;.......          ......    //
//    ......    ...':cldddl:'.    .,cllllx0KXXXXXKK0Okxl:,';cllddddooollc:,,,''...  .,cdOKKKKOkxoc::c:,...'..          .......    //
//    .....        .,ccc:;''..  ..:dkkdoodk0XXXXXXK0Okkkd;..';:loooolcc:;,,,,,.. .,lxO0KKK00Okddolllc;;::;;,,;'......  .......    //
//    .....  .       ..;,'...''.';:cldddxdoxOKXXKKOxkOxoo:. .;clllcc:;;,,,,'.....:kKKK00Okxol:;;:;;;;coolc:clol;'.......',,,'.    //
//    ........... .    ..',:ll::;::;:::coddddk0KK0ko;;:;..   .'''.....',,'......,d0KK0Oo:::;::::;;'.',,,,,,,,,;;,''...','',,,'    //
//    ........... ..   .,;cddodxocccclcloolloodOKKko:...            ............lkOO00k:':::::,........ ... ....',,,,;;,'''...    //
//    ........        .,,..:oxkkd:;:c:::;;,',;:lddl,..              ...........:xOO0OOxc::;,'.. ...''''....   ...',,;,'.'''...    //
//    ......          ..  ,dOKKKOdllccloc:;'.......                ..'''''....;dkOO00Odc:,'....,:clooddo:;,'.....''','.''.....    //
//                       ,x0KXXXXKkdddddol:'.               .....  ..''''..'.'ldxOO00xc,'.';clcllodxkkxdlc:,,;::;,''''........    //
//                      ,x0KKXKKK0Oxxddoc:l;.          .............,'..',;:;lkO0KK0kl'..':ldoooodkkkOOxdo:,,;;:c;,'........'.    //
//                    .;x00Oxdllccccclcc:;c:..        .''...'.....'.....';ccok0KKK0Oo,.';;:lollodxxxxxddddoc:;,,,,;,''...'''''    //
//                   .:kkxl;;;,;::cclolcc;,,.    ..   .................',,,;d0000kkkc.',;;;:cccclddooolccllll;...',,'.........    //
//                   'ol;...,codxkkOOOOOOkxdo:,'....  ...............'',;cox0K000kxd:',,,,,,,:cclooc:::;;:ccc:;'..',,''.......    //
//                 .':,...':dO000KK0KK00Okkxkxdddol:;,,'.........''...';ldkO0000OOkd:;,'.....,;coxxl,',;;:ccccc,..'''''''.....    //
//              ....'....,ldkO000000KKKKK0Okxddooddxxkxxxdolcc:::cc:,..,cloxkOOOOOkl;;,,,,,,;clooodo;'.':lcc::c:,'''''''.''...    //
//             ........':ldoodkk0K0000K000000Okkxddddooddxxxxxxxxxxxdollcccldxxkkkd;'......,::;;col;...',;;;'.,;;'............    //
//             ....,;.'coolllloxO00OOOOOOOO000Okxxxxddoodxdddddddddddddol::clooddd:......'''''',;::'.'''',;;,''''........         //
//    ....    .....;c::lllodooooddxOOOOkOO0KK0Oxddooooooodollollllllcclollcc:clll:''',,,:ll;'''','...,:,',;:,...............      //
//    .............:llcclloxxdollldxkkOOOOO0KK0kxxdoc::clllcccc:::;;;,;c:;;:::::;..,''',:;;;'..';;...:c;,'',,...      ........    //
//    .  .. ...''';clodocccoddolcclodxkOOkkkO0000Okxdc,,;::;;;;;;,,,,,,,'...,,',. ...'';:;,;:;:ccl:;;;;:;,',,...       .......    //
//          .',,',cc::cllcc::clllllllllodxxxkkO0KXKK0Ol.........................  ...';clol::clooddoc:;,,'''''.  .....   ....     //
//          .,;::col;,,;ccc:;:ccloolcc::coodxxk0KKKK0Oko;'.      ....        ...........':clddlc:;,,;;;,'..............           //
//    .     .,:cclooc,'',,,,;ccclllccccllllodxkkOOOOkxxxdo:,.    ....      .   ..,;,......,lo:'''.''',;,'...............          //
//    ..    .,:::cloolllooolcccclllccccc:coddxxxxxdddxxxxkkOxc.  ....    .;lc;'.',;;,'....,cl,''..',;;:;,................         //
//     ..   ..;::;:::;,,,,,,'',:cllllcc:;,;codddddoodxkkO000OOo;....    .;oxxxdollc;'.....'::,,,'',:c:::;'..'........             //
//          ..',,,;::::clllcc:ccclollc:;,,,,:cooooooddxkkkkkOO00kl:'  .cxOkkxxdo:,,'.......,;;,,;:lddlcc:,'''.........      .     //
//          .,'...';:;;;;;,,;:::cllll:,,,,,,,,,;clooloddoloxkOO0Okdoclx000kxxdo:'..'',clooc;,;::;:llc:::,''............           //
//            .......',,,,''',,,;:cclc:;;,,,,,'..,:cllodolldddxkkxkkOO00Okkxooc,;;;;;:cccccc:;;;;::;,;;,''...............         //
//                   ..,,,,,,,;,;::cclllc:;,,''....':loddoolloxxxxkkOOOxdddooolcllcccc:::c:;::c;,,::;;;,;:;'''...........         //
//                     ..'',,'';cllllodxdoc;.........',:odoloddddxkkkxdooooolc:ccll::;'';;;,.',;,,,,,,';clc:,'...........         //
//                      ....',;;,,,:loddxxxdc;,'''''','.':loodooxkkkkdllllll:;;:cl;,'...','.........'';ccccc;,,'.......           //
//                         .',,',:ldddooodxxxxdcc;':cc:;'.':loodkOOkxlcllllc,',,,,..................';:cccc::;,,'.. ..            //
//                         .,,',:coooccclooddddc;;;;,;;,'....;oxkxxddolccc:;;,''''...'''............'',,,;;;;;;,,...              //
//                        ..,;;;:clll:,,;:cloooc'.,;'','......:kkdoc:cccc:,,;;;,,,''',;,'.....................';,''..             //
//                     ...,,;;;:::ccc:,,,,;clllc,';;,;;'......:ddolc::ccc:'.',,'',,,;;,'..'.....  . ..''',;;'.',,,,,,.            //
//                .',;;;;;;,;;:::::cc:;;,,;:::;;,,;:;;,.......coc;,,;:c:,'...','............    ......',;,';;,,''''';;.           //
//              .,:lol:;;;;,;;;;::::;;,,,;:::::;;;,,''..',,..;c,...',;'.........          ..    ......,;c:'';:c:,,'''''.          //
//           .':llcclol:,;;;;:ccclccccllcldxkkkxoc:,''..',,'',;,,;;;,,..........              .........';;,'',;;,,,,'''..         //
//          .;cloxdlcllccllooodkkkkxdddddddk00Okxxxxxdoc:;:;:cllccc:'...............        .........'..''''.';,;:;;;'.'..        //
//         .collooooodoooooxxxddkOkxdooddxkxxxxdxkkxxOOkdc;;:clllc;'...',;,.....,;:;,.      .......',:;.....'''',;,;::,.....      //
//        .;llccldollddddddddxkxkOOxoloddxkkxdxxxOOkxxxkkdl:;;:cc;'.....;odl:;,,,;cll:.  .. .....'..,;,...'...,;;,...,;,.....     //
//     ..,cllcc:cc:colodolc;;coooxdlccllllodxddxxxdddddxkkdolc::;;;;;;;.'ldollc:::;'..    . .....''',,'.......',,,,...',,'...     //
//    ';ccloddolodlcclllccc:;;;::ccccllllllllodolllcloddddlcc:clllloxkko;:lllooooc;'.     .  ....'''''..'......'..'......''...    //
//    ,;clodxdddddxxdllodxdodooxdc;:cclllllllll::cc:coddoldxxxxkkxxk0000kooxxoooc;;;'.    .. ..........',,....',..............    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract IYSL2 is ERC721Creator {
    constructor() ERC721Creator("In Your Sleep Last Night 2", "IYSL2") {}
}
