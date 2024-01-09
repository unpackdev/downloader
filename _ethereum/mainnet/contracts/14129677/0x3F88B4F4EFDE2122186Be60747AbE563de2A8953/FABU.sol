
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fabula Photography
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    ···········▄▄▄ ▄▄▄· ▄▄▄▄· ▄• ▄▌▄▄▌   ▄▄▄·                                                                                                                                                                   //
//    ··········▐▄▄·▐█ ▀█ ▐█ ▀█▪█▪██▌██•  ▐█ ▀█                                                                                                                                                                   //
//    ··········██▪ ▄█▀▀█ ▐█▀▀█▄█▌▐█▌██▪  ▄█▀▀█                                                                                                                                                                   //
//    ··········██▌.▐█ ▪▐▌██▄▪▐█▐█▄█▌▐█▌▐▌▐█ ▪▐▌                                                                                                                                                                  //
//    ··········▀▀▀  ▀  ▀ ·▀▀▀▀  ▀▀▀ .▀▀▀  ▀  ▀                                                                                                                                                                   //
//    ccclcccccccc:::cccccccllllcllllllllllllcc::ccllllccccccccccc:::::::::ccc::::::::::::::;;;;;;,,;::::::::;;;;;;;;;;;;;;;;;;;;;;,,,;;;;;;,,'''',,,,,,,,,,,,,,,''''.......''................................    //
//    lllllllllllcc:ccccccllllllllllllllllllllcccccllllllllllllllc:;;:ccccccccccccccc:;;;;;;,;;;;,'',;;;,,,;;;,',,,,,,,,;,,,,,,,,,,,,,,;:;;;;,,,'',,,,,,,,''','''''''''..'''''''''............................    //
//    lllllllllllccccccclllllllllllllllllllllllllllllllllllllllllc:;;:llllc:;;:cllcccc;,,;:::::c:::;;::::;;::::;;::::::::::::::::::::;;;::;;;;,,,',,'',,,'''','''''''''''''.''''''............................    //
//    llllllllllccccccccllloooolllllllllllllllllllccllllllllllllllc::cllllc:;;;cllcccc:;,;:::cccc:::;;::::::::::::::::::::::::::;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,''',,,,'''''.'','''''..........................    //
//    llllllllllcccccccllloooooolloooollllllllllllllllllllllllllllllllllcccccccccccc::::::::;;:::::;;;;;;::::;;;;;;,,;;;;;;;;;;;;;;;;;,,,'''',,,,,;;;;;;;,,,,,,,,,,,,,,''',,,,,,,,''.......     ..............    //
//    llllllllllccccclllloooooooooooolllloooolllllloolllllllllllllllllllcccccccccccc::::::::;;:::::;,,;;;;;;;;;,,,,'',;;,,;;;;,,,,,,,,,,,'..'''''',;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,'........      ..............    //
//    lllllllllllccccllllooooooooooolllllllllllllllllllllllllllllllllllcccllccccccccccc:::::::::::;;,;;;;;;::::;;;;;;;::::::::::;;;;;;;;,,''',,''',;;;,,,''''',''''..''',,,,,,''''........   ...........''....    //
//    llllllllllcccclllllooooooolllllllcllllllclllccllclllllllllllllllllcllccccccccccc:::::;;;;:::;;,,;;;;;;::::::;;;::::::::::::::::::;,,,,,,,,,,;;;;;;,,,''''''.....'''.................      ..............    //
//    llllllllllllllllllllllllolllllcccclllllllllcccllllllllllllllllllllccccccccccccc:;;;;;,,',;;;,,,,,,,;;;;;;;;;;,;;:::;;,,;;;;::::;,''',,'',,,,;;;;;;,''''''.....''''......'''''..........    .............    //
//    llllllllllllcllloooooooooolc;,,,;;;::cclllllllllllllllllllllllllolllllllccllllc:::;;;;;;;:::;;;;;;;;;;;;;;;::::::::::;;::::::::;;,,;;;;;;;:::::;;;;;;,,,''......''''''',,,,,,,''''........    ..........    //
//    llllllllllllllloooooooooooo:,...........',:cooooooooooooooollllllollloooooooollcccc::::;;:::c:::::::::::::::::::cccc::::::::::::;;;;;;;;;;;;::::::;;;,,,,''.......'...'',,,,,,,,,,''......     .........    //
//    llllllllllllllloooooooooooo:'..........    .':loooooooooooooooooolllllllllooollccccc::;;;;:ccccccccccccccccccllllllccccccccccccccccccccc::::cccccc::;;;;;;,,''....'.....,,;;;,,,,,,'''....      ........    //
//    llllllllllllllloooooooddddl;'...........      .';cooddddddoooooooolllllllllllllccccc:::;;;:::::cccc::ccccccccllcclllllcllllllccccccccccccc::ccccccc:;;;;;;,,,'......'...',,,,,,,'''.....     ...........    //
//    llllllllllllllooooooodddddl;'..........        . ..;lodddddddoooooolllllllcccccccccc:::;;;;:::::::::::::c:::cccc:ccccccccclcc::::::;;::::ccccc:::::;;;;;;,,,,'......'....',,,,,,,,'.....................    //
//    llllllllllllloooooooooooooc,''........       .;;,....'codddddddoooooolllllccclllccccc:::::::cccc::ccc:::::::ccc:ccccccc::cccc:::::::::cc:::::;;;;;;;;;;;,,,,,'.......''...';;;;;;;,''.........   .......    //
//    lllllllllllllooooooooddddoc,''........      .:oolc;;,,,:odddddoooooollllllcccllllllccccc:ccccccc::c:cc:::ccccc::clccccc::ccc:;;,,;;;;:ccc:::;::;;;;;;;;;;,,,,,'......'''...';::::;;;,,,'...    .........    //
//    lllllllllllllllooooooooooo:'''.......      .;oddooc:cooloddddooooooollllllllloolllllllcccccccc:;,,;:ccc:::ccccccclcccccccccc:;;;;:::cccccc::::::::;;;;;;;;;,;,'.......''....';:::;;;,,,'.....  ......'''    //
//    lllllllllllllllloooooooool;''.......       ,ooc:lllc;:odddddddoooodoollllloooooollcccclllccccc:;:;:cccccccccccccllc:::cc:::::;::ccccccccccccccc:::;;;;;;;;,;;,'''..''',,''...';:;;;,,,',''.'..........''    //
//    lllllllllllllllllcccccc::;''........      .lo,.:c;,:c:lddddddddooddollooodddooool:;:;;llllllc::::;:clcccccccccccccccccccccc::::cccccccccc::::::::::;;::::;;;;;;;;;;;,,''......';::;;;,,,'''''........'''    //
//    ccllllllllllllllllcc::;;,'.........      .;do;;olc;:cloooodddddddddooooddddddoolcc:ccclllll:;;::::clllc::ccc:::ccccc:::::::::::::::::ccc:::;::::::::::::::::::;;;;;;,,'.......';::;;;,,,''.''.   ...''''    //
//    cccllllllllllllooooollc::;,,..           .ldl;col:,:odddddddddddoodddoooddddol:cccccoolllcc::cc::cllllc::::cc::ccccc::::::::::;::;;;;:cc::;;;:;;;;;::;;;;;;::;;,,,,,''''.......,::;;,,,,''''''.....'''..    //
//    ccccllllclllllllllollooll::;'..          .:c:,''..,ldxxdddddxddooddxdolodddo:,,::c:;colc::;:cllllloollc::::::::cccccc:::::::::::::::::ccc::::::;;:::;;,,'',,,;;,,,;;,,,,'.......;:;;,,,''..  ....'''''..    //
//    cccllllllllllllllllcc:cclllc:;,'....     .........;oxxdddddddddoodxxdlloddo:,;:;;cl:;cl:;:::llllllllllc::ccllllllllllccccccc:::::::::ccc::::::::::::;;;,'''...',,,,;;,,,''''....,;:;;;,,'...... ..''''''    //
//    cccllllllllllllllllllc;::cccccc::::,.. ..,'.......'ldddddddxdddoodddoooddo:,:c,;l:;c:,;coolllccclooooolclloooooolllllllccccc:;;;;;;;;;:::::;;;;::::::;;;,,,'''''''''',,,,,,,'...'::::::;;;;,'...........    //
//    clllllllllllllllllllll:,,,;:cllllll;...;llllc;,'...,oddddddddddooddddooool;:o:.;l:.,cclodddooolllllllloooooooolllccccc::::::;;,,,;;;;;:::::::::::::::;;;;,,'.',,''.....''',''...,:cccccc::;'.... ..'''''    //
//    llllllllllcc:::cccccccc;,...'cooool;',clollllllcc:;;:llooolccllooddddddodc:od;'cl,.,:cdddddolcccllllllcccccccc:::::::::;;;;;;;;,;;;:ccccccc:::::::::::;;;;,'',,,,''........'.'',::ccc::::::;,,'...,,,,''    //
//    cllcllllcccc:::::::;:::::;,,coooolc,,cllllc:::;;:cccccccccccc::coddddddddl:lc;:l;'';lollodddoooolcccccccccllllllcccccccc:::::::;;;;:ccccccc::::::cc:::;;;;;;;,,,,,,'.........';::cccc::::;'......',;,'''    //
//    clc:cccllllllccclllllllclloodddo:....;llc:,'.....',coooollloollccllooollooc:;:c;,:lolcclodddolcccloodddddooooooooolllllccccccc::::::ccccccc:::::::cc::;;;,;;;;,,'',,,,'....  .,:ccccc::::;,'....',;;,,''    //
//    cllllllllllllllllllllollloddddxo'....:xxxxol::;;,'',clccccccccc::cccccc:cllc:cccloooloddolc::clodddddddddddddddoolllcllccccccc:;;;;;;::cccc::;;::cc::::;;;;;;:::;;;;;;;,;,...  .,:::;;;::;,'''',;;;;,,''    //
//    llllllloooolllcclllloolllloddddo;....cxxxxxxddol:;'',:ccccccccc:ccllllllllllooooooooolcc::clodddxxxxxxxxxddddddooolllllllclllc:;;;;:::ccclcc::::ccccc:::::::::::;;:;;;;;;;;,..  ..,;;;;::;,,,'''',;,,,''    //
//    llllllooolllllllllooooooooodddddol,.'oxkxdlc:;;,''...:odddddddddooodddoooodddollccccccclodxxxxxxxxxxxxxdddddddooooooolllloooollccllccccccllcccccccccccccccc:::::::::;;;;;;,,''.....::::::;;;,,,,,,,,,,''    //
//    llllllllllllllllllooooooooolc:;;;;;',cllc;'..........;oxdddddddddxxxxxxxxxxxxdddooodddddddxxxddddddddddddoooooooooooolllooooolcccccccccccccc::;;:cccc:;::::::::::::::::::::;;;,....':ccc:::::::;',,;;,,,    //
//    lllllllcclllllllllloooooollol:'............',;;;,'...;oxxxxxxxxxxxxxxxxxxxxxxdddddddooddddxxxddddddddddddooooooooooollllllllll::cccccc::ccc::;;;:ccc::;;,,;;;::;;,,,;;::cc::::;','..':cc:::::::;,,,;;;,,    //
//    lllc:::::cccllllllloooolcloooooc;........  ...',;;,',codddddddddddoooooddddddooddddddddddxxxdddddddddddddooooooooooolllllcccllc:c:::::;:cccc:;:;:cccc:::;;;:::::;;;;,;;:::;;;;;,,'. .';::::::::;,,;;;:;;    //
//    clcccccc:cllllllooolooollloooolc;'...,:,...............',,;;coddddoooooddddddddddddddddxxxxxdddddddddddddddddooooooolllllllllolccc::::::cccc::c::ccccc::::::::::::;;;;:::;;;;;;,'..  .';:c::c:::;,;;::::    //
//    llllllccc::cllcloooooooddddddoool:,,:oo:......... ..........,ldxxdddddddddddddddddxxxxddddddddddddddddddddddddooooooollllllllllccccc:::ccccccccc:ccccc:;;;;;:;;;;;;;,;:::::;;,'.....  .,:c::::::;,,;::::    //
//    lllllllccc::cc:ccloooddddolcccccccloddo;..................',cdxxxxddxxxxxxxxxxxxxxxxxxxxxxxxdddddddddddddddddddooooooooolllllllllllcccccllccccccccccc:::;;;;;;;;;,,,,;::::::;'''........;cccccc:;,,;::c:    //
//    llooooollcllccc::clloool:;,,:oooddddddo:...............',;::looddoddddddddddddddddoooddddddxxdddxxxxxxxxxxxxdddddooooooollllooollllllccllllllccllclcccc:;,',,,;;;,'',;::::::;;,,'''.....':ccccc:;;;:::::    //
//    lllooooooolllccccc::cc;'',codl;',clolll:,'''.....'',;,;:cccllloodddddddddddxxxdddoooddddddxxxxxxkkkxxxxxxxxxxxdddddddoooooooooollllllllllollllllllllcccccc::;;;;;,,,;;::c:::;,,;:;;,.....,ccccc:::::::::    //
//    lllloooooollc:::ccc:;'.':oooool:,'';;;;:ccc:;,'',:loddooooooooooddxxxxxxxxxxxxxxxxxxxxddxxxxxxxxxxxddddddddddddoooodooooooooooollllllllllllllllllllllcccc:;,'';:;,',,,;::::;;;::::;;,.....:ccccc:::::cc:    //
//    ccccllolllooollccccc:,',ldl,,cddolc:;'';::;,'.':ldxdxxdxxxxxxxddxxxxxxxxxddddddxxxxxxxxxxxxxxxdddddddddooooooooooooooooooooooolllllllllllllcccccclllllccc:;,,;:::;;;,',;::::ccc:::;;;,....;cccccccccccc:    //
//    cccclllllloooddoollc;,',:loc;,,,:odc'.......'coddddooodddxxxxxxxxxxxxxxxdddddxxxddddddddddddddddoooooooooooooooooooooooooooooollllllllllllcc:::;:llllcccccc::::c:,,,;:::::ccllccc::::;'...,clcccccclllc:    //
//    llllllollloddddddoc;''''.':lol,..';'..''....:dxxxxddddddxxxxxxxxxddddddddooodddddoooodddddddddddddddddoooodddooooooooooooooooollllllllcclccc::c::cllllccccccc:;:::::;;::cclllllllcccc:,...,cllllllllllc:    //
//    lllllloollooodoo:,''.'''...,:c,',,',;::,....':oxxxxxxxxxxxxkkkkkkxddddddddddddxxddddddxxxxxxxxxxxxxxddddddddooooollllllllllllllllccccccclccccccccllllllcclllc:;,,;::;;:::llollllllccc;'...;llllllloollc:    //
//    llllllllllooool:,',;'',,'....'.,clllc;'.......,cdxxxxxdddddxxxxxxxdddddxddooddxxxxxxxxkkkkkkkkkkxxxddddoooooollooooolllllllllcccc:::cccllccccccccllllccclllcc;;,,;:cccc:cloooollllccc:'...:lllllllllllc:    //
//    llllclllc::cllc;,;c:,.,;;'....''..........,,..'';oxxxxxxxxxxxddddddxdxxxxdddxxxxxxxxxkkkkkkkkkkkxddoooollloolllloolllllllllccccccccccccllccccccccllllccccc:::;;,,,;:ccccclloollllcccc;...,cllllllllllcc:    //
//    llccccc;;;:clc;,,;cc,.'::;'..,:;......''',::'';,',cdxxxxxxxxxdddddddddddddddddddooooodddxxxxxxxxxxddddoooooooooollllllllcccllllllccccccllcc::cc:;:lllccccc:::ccc:,,:clllllllllcc::cc:,...;llllllllllllc:    //
//    lccc;,,;:ccll:,,,:c:,.':c;'.'':c,.....;,';c:'.,:;,';ldxxddddoooooddddooooooooodolcccclooooodddxxddddddoooooooooooooolllllllllllllllcccclc:;;;:c:;;ccc:::ccccccccc::clllllclllllc::cc:'..,cllllllllllllc:    //
//    cc:;,:cllcll:,,,;cc;'.':c:,''.':c,...';;',::,'',;''',cdxxxxxxxdddxxxdxddddddddddoooooodooodxxxxxxdddddooollllccccllllllcclloollllllcccllc;,;,;:;,;ccc:;,,;:cc::cclllllllcccllllccccc;'..;lllllllllllllcc    //
//    c:,;clllc:cc;,,,:cl;'.';cc;,,'.;lc;...,:,,:c;;;',;,,,;lddxxxxxxxxxxxxxxxkxkkkkkxxkkkkkkkkkkkkkkxxdoooolllllcc:::ccccccccclodooolllllllllc:;;;;:;,;ccc::;;;;:::::clllllllccccllc::cc:,..,clllllllllllllcc    //
//    ;'':lllc::cc,'',:lc,'''':cc;,'.',,,...,:,';c:,;;'',;,,,cllllooddddddddoooooooddddddddddddxxxxxddoolllllllllccccclllllllloodddoollllcclll:;;;,;:,',:cc:;;;,,:c:;:clllllllcccllc::::;,..':llllllllllllllcc    //
//    ..'cllc:;:cc;',;cc:;,''',cc;'',:,.','.,:;',cl;';;'',;;,;:ccclloodddddolllllllodolllllloooooooooooooooooooooolooooooooollllooooolllllclllccc::::;,;:ccccc::::::;:clllllllccccccccc:'..':lllllllllllllllcc    //
//    ..,llc:clllc,',;ccclc,,,,:cc,'';:'.,;,,::'';lc,':;'',;:::loloodddddddoooollloodoooooooooodddddddddddddddddddooooooooooooooooolllllllccclc::;,;:;,;:ccc:::,;:::;:clllllllcccccccc:,...:lollllllllllllllcc    //
//    '.:cc::llol:,',:::col;,;,;cc:,.';;'...,::,''co:',:;';;,:lolloodxddddooooooooooddddddddddddxdddddddddddddddddoollllllllllooooolllllllccccccc::cc;',:cccccc::c:;;;:cllllllcccccc:;'..':looolllllllllllllcc    //
//    ',clccllool:,',:;:lol:,;,,:cc;'.':l:'.';::,';ll;,:;',;,;loooooddddddoooddddddxxddxxxkxxxxkxxxxdddddoooddddddddoooooodddddddddoooooolllccccc::cc;,,:cccccccc::;;;:cllcccccccccc:,..,cloooollllllllllllllc    //
//    ':llllooool;',;;;cool:,:;,;cl:'..;cl;.,;;::,;loc,;c,';;;coddddddxxxdddxxxxxxxxxddxkOOOkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxdddddddolllllllllccccc:cclcccccc:::;:::ccccc:::ccccc;..;cooollllllllllllllllcc    //
//    ,clcclooooc;,;c:;coool:::,;clc,'..,::,,:;,:;,col;,:c,';;;cloooddddoooooooooooooooddddddddxxxxxxxxxkkkkkkkkkkxxxxxxxxxxxxddddddooollllllllllcccccccccccccccc::;;::ccccc::cccc:;'';looooolllllllllllllllcc    //
//    ,llllloool:,;:l:,:odoolc:;;cc;,,'..,:;';:;,,,coo:,;c:',;:;;::cloooooolloooooooooooloooooooddddddoddxxxxxxxxddddddddddddoooooooooollllclllllllllcccccccccllcccc::cccccc:::::;,'':lollllllllllllllllllllcc    //
//    :llloooooc;,;clc;;loooc::;:c;,,::'.';:'',c:'';loc,,cl;,,;:;;::ccllccclooddddddddddddxxxxxxxxxxddodxxxxxddddddddoooooooooooooooooollllllcccccclcc::;:cccccccc:;;:ccccc:::;,'..,clllllllllllccccclllllllcc    //
//    clllooool:,,:clc:;:looc::;;;;,,:c,..,:;,';c;',:oo:,:lc;,,::;;:ccllc;;cloooooooooooooddooddddddolloddddddooooooollllooooooooooooooollllcc::cllllcc::ccllllccc:;;:ccc:::;;'..';cllllllllllllccccccccclllcc    //
//    ccclllllc,',:lllc::clllc:;;;;;;''...':c;''::,,;loc;;;cc;,,::;;cllllccoddxxxxxxxdddddddoooddddoollooddddooooooollllllollloolllllollllcccccclllllllllllllllcc::::::::;;,'..';clllllllllllllcccccccccccllcc    //
//    ,;::clcc;'',:cllllllloolc:;;;::;;'...,::,.,c;';coc:c:;cc:;;cc:lollloollooddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddddddoooooooooooooooooollcccccclloollccccccllllcc:::::::;,'..,;clllllllllllllllcccc:ccccccllcc    //
//    ::cclll:,',;:lc:cllooollc:;:cc:::;'';;:c;'':;',coc;cl:;clc::cc;,:ldddddooolooddxxxxxxxxxxddddddddddddddddddddddddoddddddoddddddooolllllllloollc:::::cllllccc:::;,'..',:cllloololllllllllllccccccccccclcc    //
//    ;:cllll:,,;;clc;;::cllllc:::::;;::,';::c:,.;:,,:ooc:ll:;cllcc:,;lxxxdooodddooooodddxxxxxxxxxxddddddooooooooooolllllllllllloddddddooooollllolllc:ccccclcccc:;;,'...,;:ccccclllllllllccllllcccccc:::::cccc    //
//    :cllllc;,;:cclc;;,,;cllllc:;,;:cl:'.';::c;.,:;,:odl:col::cloolc:cdxxxoc:cldddddddddxxxxxxxxxxxxxxxxxxxxdddddoooolooolllllloddddooolllllllllllllcccclcc:;,,'...',;cllc::;,,:clllclllllllllcccccc::::::ccc    //
//    :cllll:,;:clllc;::::cllllc:;,,::c;'....;c:''::,;ldo::loc:cclodolclodxxxddxxkkxxdddxdddddoooddxxxxxxxxxxxxxxxxxxxdddddddoooooooooollclllllllllllccc:;,''...',;;:clllc:;;;,,;:cc:::ccclllllccccccc:::::ccc    //
//    :clllc;;:cclllc::::cllllc:;;;;:::,..,;,,cc'.;:,;ldoc:lol:cl:codddlclodxxxxxxdoodxxxdoooooolloodddxxxkxxxxxxxxxxxdddddddooooooooooolllllllllcc:;;;;;;;;;::::::::cccc:;;;;,',;,'',:::ccclllcccccccc:::::cc    //
//    :llll:,;:clllcc:;;;:clllcc;,,,;:c,....',cc,.;:,;oddlclll::lc;:codddolodxxdolloxkkkxddooooolooddollodxxdddddddddddoooooooooollllllcc:::::;;;;;;;::cccccccc:;;;;:cccc;,,,,,.''......,;:cccccccccc:::::::cc    //
//    clllc;,:cllolccc:::ccllllc;',;ccc,.....:lc,';,':ddollc;cc,:l:'';coddolccc:codkkkkkkkxdxkkkkxxxxdddddddddoolllllllllllllclcccccccc::::::ccccllllccccccc::c:;,,;::cc:;;;,,'.........,;;:ccccccccc::::::::c    //
//    clll:;:clooooooooooooooooc;;;;;;;,''..;loc:;,',lddolc,,cc;,cl:'',::,;c:;:cloxOOOOOOkkxdoloooolcclloddxxxddddddooooooooooooooooollllllloooolllllccccccc::cc:;;::cc;,,,,'..... ..,::ccc::cccccc:::::::::::    //
//    lllc;;cllooooooooooooooolc;,'..';,.',:llc:;,'':loool;,;;;;,,::,,;:;..',;ccclxkOOOOOOkkxxxxkkxdoddddddxxxxdxxxxxxxxxxxddddddddoooollllooooooolllllllcccccc::::::::,.'','....  .,:::ccc::::c::::::::::::::    //
//    lllc;:lloolcccc::ccllollc;'',;::,.';::cl;'',;;,;ldl;,;;.',,,,'';;'.....'';okkkkkkkxxxxxxxxxdoooolllodxxxxxdxxxxxxxxddddooooolllllllllllllllcccccccc:::::;;;;;,,,,'......... ..;::cccc:;,;:::::::::::::::    //
//    ool::clllllccc:cccclllllc:,;;:;'.,;,,:c;',cc;',loc;,;;''''',;,...........,cokkkkkxxxxxxkkkkxxddddddxxxxxdllooooddddddoollcccccllcc:::::::::::;;::::::;:::;;;;;;;;'.'....... ..;ccccccc:;::::::::::::::::    //
//    oolcccllllllllllllllllool::cc:',;;',::;,clc,';lo:,;c:'','.';;;,...........';okkkxxxkkkkkkkkkkkkxxxxxxxxoclodolcc                                                                                            //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FABU is ERC721Creator {
    constructor() ERC721Creator("Fabula Photography", "FABU") {}
}
