// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Abery On Chain Photographs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    MMMMMMMMMMNd,'';kMMMMMMMMMNl',,'......','.'....',,;;:clccccc::;;;;:cc:;;::;:;;:;;:::::::::::::::::;,;,,,'''.';;'',,,,;:ccccc:cccccc:;,''''............    //
//    MMMMMMMMMWx.    '0MMMMMMMMWx;:;'.......'''',,;;;cccccc:::;,,,,,;;;;::::::::;:::::::::::::::::::::::::;;:;;;,;:;,',,,;;:ccccc::cccccc;,'.''............    //
//    MMMMMMMMM0'  ..  cXMMMMMMMWOooc,...'''',,'';;;;;;;;,,;,,,,,;;;:::::::::::::::::::::::::ccccc::ccc::::::::::;;::;,'',;;:cccc;;:c:;:cc:;''''.''.........    //
//    MMMMMMMMX:  ,Ol  .dWMMMMMMWOddo:,,;:;,,''';;,',;,,;;,;:;;:::;;::::::::::::::::::::::ccccccc:cccccccc:::::::;::::;,',;;:ccl:,;cc;,;:cc;,'..''..........    //
//    MMMMMMMWd. .dW0,  'OMMMMMMWOddo:;cloo:'..';;,;;:;;;;;;:;;;;:;::::::::::::::::::c:::ccccccccccccccccccccc:c::::c::,',,;;:cl::ll;,;:cc:;,,'.............    //
//    MMMMMMMO.  ;0XXo.  :XMMMMMWOcc:;;:oddl,'',;:,',::;;;;;;:;;::;::::::::::::::cc::cccccccccccccccccccccccccccc::::::,'',::;colclc;;:::::;;,''''''........    //
//    MMMMMMK;   .....   .oWMMMMWk::::;;:ooc;;,',,'.,:;;::;,;::;::;;:::::::c:::ccccccccccccccccccccccccccccccccccc:::c:,',cc:codoc:::clc::;;,,'''''.........    //
//    MMMMMNo   ',,,,,,.  .OMMMMWd;cc:;,;coc;,,,'''';::::::;:::;;:;:::::::ccccccccccccccccccccccccccccccccccccccclccc:;,,col:coooccllc::;;;;,''''''''''.....    //
//    MMMMMk.  :XMMMMMWd.  ;XMMMWo';::;;cddc,''''..',;::;::::::::::::clllccccccccccccccccccccccccccccclllcclllccolccc::,;odlllllccccc:;;;;;;,,''''''''''.'''    //
//    MMMMNo'':0MMMMMMMXl'';kWMMWd,;,::codo:'..,,'',;;::::cloollcllloooooolcccccccccccccccccccccccllllooc:collclollllcccodolloocclcc;;,;;;:;;,'''',,,,,,,'''    //
//    MMMMMWNNWMMMMMMMMMWWNWWMMMWx;;',coddc,...',,;:::::clllooooooololccclooccccccccccccccloodoclooolodollolclclooddolodddoodoc:llcc:;;:c:;;;,,,,;:::;,;;;;,    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWk;'',cooo:'..',::::::cllccccccccccccccccllllllllcccloooooddddlccclloddddddololloxddddddddoolc:cccol;;cc:::c:;;:;;:cc:;;::;;    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWx;'.,:clc,''.';::::cccllccccccccccccccccccclddddxdodddooolllooolodddxxxxddollooodocldddddolccclodoc;:c:::c::;;;;;;;;:::::;;    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWx,...',''',,.';:cccccllccccccccccccccclccccccodxxdooddxxl,':ldxxxxxxxxxxdlllooddollddoddlloollloo:;cc:ccc::c:;;:;;;;;;;;;;;    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWx:;,,,,,:::::loooodddlccccccccccccccccclccc:;codddoodxxo:'.;lddxxxxxxxxdlllooooooooolodooodlclodlccllcc:;:cc:;;:;,,;;::;;::    //
//    MMMMMMWWWWWWWWWWWMMMMMMMMMWkclcclloddooodkxddxkxdlcccccccccccccccccllc:;:loddxxkxo;'..,codxxxxkkxdlccoddoloddddddddoodoooodolooocc::cccc:;;,'';:ccccll    //
//    MMMMMNo,,,,,,,,,,:o0WMMMMMWOooodolodxxxxxxxxxxxdolcccccclccccccccccclc:,;coxxxkxl:'...,cddxxkkkkdolodxddodddddoddoodoodddoloollcc;,;clc::;,'',,;cccllc    //
//    MMMMMX;   .'''''.  .oNMMMMWkoxxxxdooxkkxxxkkkxxdlcccccccccccccccccclclccccoddxkd;'...':odxxkxxxxxdxxxxdooddooooddoodooddoc:lolll:;;:ooc:;,,,;'':ccclll    //
//    MMMMMX;  ,0NNNNN0:  '0MMMMWkldxxkxollooddxxxkkxocccccllcccclllccccc:::::;;clool;.....:ooooddxxxxxxxddddooolclooooddooool:cllllolc:codol:c:;,'';cclddxd    //
//    MMMMMX;  'kKKKKKk,  ;XMMMMW0ddxxkxoccccloddxkkxocccc:;:clcc::;;;;;;,'',,,':cc;'..''',:oooxxdddxxddxddddoolllolodoododdollolloddoccldoccloc,'';ccldkO0O    //
//    MMMMMX;   ......   ;0MMMMMWOoxkkkkxoccccclloddoc;;;;;,;clll::;:lolcccccllc:;,..',,;;:odddoodxxddxxxxdddddollloddoodoodooddooddollodl:cldl;,',clldxOKKO    //
//    MMMMMX;  .,:::::,.  ;0MMMMWKxxkkkkkxolcclooloooolloooddddxxdoodkdlccllllc;'....,;:cooododddddddxxkxxxdddddlldddddddoodddddooddodooollool:;;;;cllxO0KKO    //
//    MMMMMX;  ,KMMMMMWd.  cNMMMMXkkkkkkkkkxdoolllodoookOOOOOkxOOdldxoc:c::;,''.....';lddxdoooodddddxxddxxxddddolldddooooodxddollodoooooloddo:,;ccclllxkOOkd    //
//    MMMMMX;  ,KWWWWWXl.  lWMMMWKxxxkkkkkkkxxddooolldO000OOkkOkdloxo;''''....''....',coddddddxxxdddddxxxxddxddoodddooloddddolllodoloollododl;::loc:clodolll    //
//    MMMMMX;   ',,,,,.   :KMMMMMKkxkkkkkkxxxxxkxxxddxOOOOkkO0Oxodxo:''.''''''''.....';lddxxxxxdxxxddxxxxxxxxdooddllooodddddloddddooooooodoc:ccodl;;clcccccc    //
//    MMMMMNo'''''''''':lkNMMMMMMKkkkkkkkkxxkkkxxkxxxdxxxxxxkOkkkkdc,''''''''''.......':odxxkxddxxxdddxxxkkxxdddoollodddolooodxxxxdoddoodol::lllc;;:cc:ccccc    //
//    MMMMMMWNNNNNNNNNNWMMMMMMMMWXOkkkkxxkkkkkkkkkdoloxxxxdxxdoddol:,''''''''''........'cloooddoddddxxkkOkxxdxxdoooooddolloooxxkxxddooooolllloc:cc::::;;;:cc    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWKOkkkkxxxkxxxxxxxolccodxxdddddoolc:,'''''''''.........';cloddddddxxxkkkxxxxxxxddooddddoodddxkxxdddolloooloolclolc:;;;:c::cc    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMW0xxxkkkkkkkxxxdddl:clllodxxddxxdo:,''''''''''.........';cooddxxxxxxxxxxxxxxdddddddddoolooddddddooolllooooolloolc:;;:cc:cccc    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWOdxxkkkkkxxxxxdoooccllloddddxxolc;,'''''''''..........';coddxxxddxxxddxxxxxddddxxddddddooodolllcllloooddlcldooc:;:::::;:ccc    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWOodxkkkkkkxxkxxxdddoolclollldolc:,'''''''''...........':ldxxxxxddxxxxxxdxxxxxdddddddddddoooollloolloodollloolccccloc:;::::c    //
//    MMMMMMMWWWWWWWWWWWWWWMMMMMW0ddxxxkkkkkkkkxxdololccloolodolc;'''''''''............':oddxxxxddxxdddxxxxxxddddddxdddddoolloolollloollloodolclccc:::ccc:::    //
//    MMMMMMXl,,,,,,,,,,,,oXMMMMWKkkkkkkkkkkkkkkxdolllcloxxdxxxoc;''''''''.............';coodddooodddddxxdddddxdxxxxxdddoloooolodololcloodddoc::clccc::cc::c    //
//    MMMMMMK,   .''''''''lXMMMMWKkxxkkkkkkkkxxxxxxdolloxkxxxxdl:,'''''''..............'',,,;:::::ododxxxxxxxkxxxxdddddoodddooddddddoloddddolllllcclcccc;;:c    //
//    MMMMMMK,  ,0NNNNNNNNWMMMMMW0xxxkkxdddddc:::cc:cclodxkkxol:,''....................''''.....,,coodoodxxxxxxddddddddddddddoodxxxdddooooolllccooool:;,,;::    //
//    MMMMMMK,  .coooooooxNMMMMMW0dxxxxdlc:;;;,,,,,,:cccloddolc;,''...............................',;;:coddxxxdddddddddxdloodxxxxxdddollllllolodooolc;;::,,,    //
//    MMMMMMK,           '0MMMMMW0xxdxdl:;,'...''''',:cclccc::;,,'...................................,cloolloddodooodddlclldxxxxddddoollllooooolllc::::;,,',    //
//    MMMMMMK,  .okkkkkkk0NMMMMMW0ddddoc:,'''.....''''',;:::;,,''.....................................,;:::cllodddddddolododxxxdolllllllloooolcclcc:::,,;:;;    //
//    MMMMMMK,  ,KMMMMMMMMMMMMMMWOdddoc;,'''.......''.....'''''''......................................';:::cloddddddooodddddddlc::looollcclllll:::;:c::c:::    //
//    MMMMMMK,  .okkkkkkkkkXMMMMW0xxddo:'''''...........................................................';,;cooddxxxdolloooclolccloooolllclllccc:cllddlc:;;,    //
//    MMMMMMK,             oMMMMWKkkxxxo:;;;,'............................................................':cloddxxdoloddoc:ccloooolooolllcc::cloodoolcc;,''    //
//    MMMMMMNkooooooooooooo0MMMMWKkkkxdl;,,''.............................................................,;:coddddddddoolcclclooodooolll;;:coooooool:::::,'    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMW0xxxxdl;'.................................................................,;colloddollclcclllooooooool:;:llcllllllc::ccc;;;    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMW0dddool:,..''',,,,,'.......................................................';:;:clccolccloddoolodxxdllllllllc:ccllccccccc:;    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMW0xkxddoc;'.'';;;;;;;,'.'.....................................................'',::::looooodddddxkdolloolccclcccodoocccolc;,    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMW0xxdddolc,..',,,,''''........................................................'',;:ccoddddddddxxxxdooolcc:cllooolllllllc;;,;    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMW0xxdolcc:,''''''''''..........................................................',,cdddddxddddxxxxxddlccccccoolccclcll;,;:::;    //
//    MMMMMW0kkkkkkkkkk0NWMMMMMMW0xkxdddolc,'.''''............................................................',:::lloddddxddxxxddolllc:cool:ccccc;;::::::c;    //
//    MMMMMX;          ..:OWMMMMW0xxddxxdoc:'..........................''''.....................................'';cccloddddxkxxdooooollllllllc;:ccccllcccc:    //
//    MMMMMX;   ;oooll:.  .xWMMMWOdxddddol:,'....''..................'''''''......................................',;;:cldddxxxxddddollccclllllloolooolllccc    //
//    MMMMMX;  .kMMMMMWd.  cNMMMW0dxxxxxdoc:;,....'.......................'.........................'.'............',;coodddxxxxddoddoollllooooooolddoooooll    //
//    MMMMMX;  .dKKKKKO:  .xWMMMWOodddxxxdlc:,'.....................................................................,:cloddxxxxxddddolooooooooolllooddddoc:;    //
//    MMMMMX;   ......   ,kWMMMMWOoooooddol:;,'.....................................................................',;coodddddddoollllcccooolllloddoccloc;;    //
//    MMMMMX;   ';;;;,.  .dNMMMMW0xxxdxxxxdocc;'.....................................................................,;:ccloodddoccllllolllccclodoolllcc:;;;    //
//    MMMMMX;  .OMMMMWk.  '0MMMMW0xkkkkkxxdddoc:,....................................................................',:lodddooooooodddoc;;clloc:codoc:,;;;;    //
//    MMMMMX;  .kMMMMMK,  .OMMMMWKkkkkkkxxxdooll:,......................'''''''''''..................................';cclcclloodddddoolcccccc:clllcc::;c:;;    //
//    MMMMMX;  .kMMMMMX;  .dWMMMW0xxxxkkxxxxdooc;,.........................'''.......................................',;;;lloddddddollllllc::cloc:;;;:::;::c    //
//    MMMMMWklldXMMMMMW0olokNMMMWOdddxxxdddooll:;'...................................................................,;coodddddooodoolllccccc::;;;;::;;::cc;    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMW0dxxxxxkxxxdlcc:'..................................................................,:::coolooooooolcccllc;;;;;:;;;;,,::;'''    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWOodxxxxkkxxddoolc,................................................................',,,,:loloollcccccccc;'''''',;:::;,'''',,    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMW0xxxxxxxxdoool:;,'................................................................'';:clooolcccccccccc;,'''',,,;;,'',,,,,,,    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWOodxdddxxdloooc:;'...............................................................';;;cllllllcccccccc:;,,,;:::::,,,,',,;;,;,    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWkclllllddddddddddc,.............................................................',:;:clllccllcccccccc::::clcclccc:;;;;:::::    //
//    MMMMMXo::cOMMMMMWkc::xNMMMWklllllcccccccc:::;,............................................................',;::ccllllldollccccccccllcccccccccccccccccc    //
//    MMMMMWx.  'OMMMWk.  'OWMMMWkldddddddol:cc:,'..............................................................':ccclllllloolllcccccccccccccccccccccccccccc    //
//    MMMMMMWk.  ,0MWO.  'OWMMMMWklllodddoollool:,'...........................................................',;cllcccclodolcccccccccccclllcllccccccccccccc    //
//    MMMMMMMWO'  ,00'  ,0MMMMMMWOloooddxxdddoolc;'...........................................................,;::cllccccllllcccccccccccllllloolcccccccccccc    //
//    MMMMMMMMM0,  ''  ,0MMMMMMMW0oodxddxxdollllc;'...'''....................................................',:cccccccccccccccccccccloooooddoddlllllcllcccc    //
//    MMMMMMMMMM0;    ;KMMMMMMMMWOoooddodddddoccc,'...'''....................................................';::cccccccccccccccclcloxxxxxxxxddddxdollllcccc    //
//    MMMMMMMMMMMO.  '0MMMMMMMMMWklllllooolllc;;;,...........................................................',;:ccccccccllcccccclllxkxxxxxxxxxxxxxollllcccc    //
//    MMMMMMMMMMM0'  ;XMMMMMMMMMWkllllllooooolc;,'''''''''..................................................';::cllllllllllccccclloxxxxxddxdxxxxxxdlcclllccc    //
//    MMMMMMMMMMM0'  ;XMMMMMMMMMWklllllooooodolc:;,'''',,'''''.............................................',:lloddoollloollllllodxxxxxddooodxxxxxdlcllllccc    //
//    MMMMMMMMMMM0;..:XMMMMMMMMMWkllllllccccccc;;,'.......'''''...........................................',;:cllllllccclooooooodxxddxdolddxxxxxxxxdlclcccc:    //
//    MMMMMMMMMMMWK00XWMMMMMMMMMWOooddoolllcc:;;,''.......................................................'',:llllllcccccllloddoooollddodxxxxxxxxxxdlcccccc:    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWklooooddolcccccc:;,,.....................................................,,,:llllllccccclodllllclllldxdxxdxxxxxxxdllccc::::    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AOC is ERC721Creator {
    constructor() ERC721Creator("Abery On Chain Photographs", "AOC") {}
}
