
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Skulls with a cigar
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    ;,,',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,',,,,,,',,,,',,,,,,,,,,,,,,,,,'',,,,,,,,,,,,,,,,,,,,,',,,,,,,,,,,,,,'',,,,,,,,,,,,,,',,,,,,,,,',,,,,,,';    //
//    ,;cddxddoodddooooolooooooolllllllllllllloooooolodoooolloollollloodooooddoooooooooooolllllllllloooooooooolllllloooooooooooollllloolooooooddddoolllllc;,    //
//    ,;kNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNk;'    //
//    ,;xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWNNNNNWWMMMMMNx;,    //
//    ,;kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXK0OkxxddoolllccclloxKWMMNk;,    //
//    ,:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l;;;;:::cc;,,,,,,,,;cxNMMWk;,    //
//    ,:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOkO0KKXXX0c,,,,,:ok0XWMMMWk:,    //
//    ,:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXd;,,;okXWMMMMMMMWO:,    //
//    ,;kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWKd;,,:okOOKNMMMMMMNx;,    //
//    ,:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOddolc,,,,;;;,;l0WMMMMMNd,,    //
//    ,:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;,,',;clodxkO0KWMMMMMMNx;,    //
//    ,:kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd:,,ckXWWWMMMMMMMMMMMMNx,,    //
//    ,;kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOkOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNx:,l0WMMMMMMMMMMMMMMMMNx;,    //
//    ,;kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOc,,,:lkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXd;,:kNWMMMMMMMMMMMMMMMMNx;'    //
//    ,;kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:,,;cl:;l0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd;,,,:okOKXNNNWWWWWMMMMMNx;,    //
//    ,;kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl,,;:looo;:kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;,,,,,,,,;:ccllooddkXWMMNx;,    //
//    ,:kWMMMMMMMMMMMMMMMNXXXXNNNNWWMMMMMMMMMMMMMMMMMMMMWNXNXk:,;::cclxo;lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWkc:cloddddddddddddoooOWMMNx;,    //
//    ,;kWMMMMMMMMMMMMMWXd:::ccccclxOKKNWMMMMMMMMMMWWNK0Odlll:,,,,,;::cl:;xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXXNWWWWWWWWWWWWWWWWWMMMNx;,    //
//    ,;xNMMMMMMMMMMMMMWk:,,clll:::;;::lkNMWWWWWNX0kxo:;;;;;;;;,,,,,,,,,,,lOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;,    //
//    ,;xNMMMMMMMMMMMMMNk:,,codxOOOxdc:::oOKOxxdoc:;;;;:cc:ccllllc:::,,,,,,;cok0NWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;,    //
//    ,;xNMMMMMMMMMMMMMNk:,,;ldkOOkkkocol:;c:,,,,,,:c:cldoloolccllcllcc;coc::,,;loxkKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;,    //
//    ,;xNMMMMMMMMMMMMMXd;,,;;lOkxxxkocoo:,,,,;;::;:ccccc::loocc:::;:clcloccllcc:;;,:lx0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKK0KKXNWWMMMMMMNx;'    //
//    ,;xNMMMMMMMMMMMMMNx;,lo:;ldxkxk0xdoc;,,;c:;;;;;,,,,,,:cc:::ccccclllllclollllc:::;;cox0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdlc:;;;::coxKWMMMMWk;,    //
//    ,;xNMMMMMMMMMMMMMWOc,;odc;;lddxxoooc:ccccc:;;,,,,,,,,,,;;,,;clcccccc::loc:cc::cc:;;;,:ldxONWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxc,,;cllc;,,,,,l0WMMMNx;,    //
//    ,;kWMMMMMMMMMMMMMMNd;,;dko::::ccccc:clllc;,,,,,;;;;;;;,;,,,,;;:lolllccllc;;,;;:;;;:c:;;,,;ldkKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMXo,,;d0XNNX0x:,,,,oKMMMWk;,    //
//    ,c0WMMMMMMMMMMMMMMWKl,,:x0ko:;,;;:clololccllcccloollooddoc;,,,;c::cccclll:;::::c:;::;;;;;;;,,:lxOXWMMMMMMMMMMMMMMMMMMMMMMMWk:,;dNMMMMMMWk:,,,;xNMMWO:,    //
//    ,:OWMMMMMMMMMMMMMMMW0l,,cdkxdlc::clooldooddc;;;;;;;;:cldddoc,,,,,;:c:::oolloddllllc::::cl:;,;,,,;coOXWWMMMMMMMMMMMMMMMMMMMW0c,c0WMMMMMMW0c,,,,lXMMWk;,    //
//    ,:OWMMMMMMMMMMMMMMMMWKxc,;:ldolclclooooddlc:;:oxxddol:;,;:odlcc;,,,,:clldollldoodol::clllcc:::;,,,,,:okKNWMMMMMMMMMMMMMMMMMNx,:OWMMMMMMNk;,,,,oXMMWk;,    //
//    ,;kWMMMMMMMMMMMMMMMMMMNOc;,,::;coooooccooc:c:;d0xldKNXOdc;;:cdkxl;,,,,:oxxlcldooddoc::cllcl:;;;;;;;,,,,:lx0NWMMMMMMMMMMMMMMW0c,dXWMMMWXkc,,,,c0WMMWx;,    //
//    ,;kWMMMMMMMMMMMMMMMMMMWXx:,,,;:lc:clcooolcc::;;lolxXWMMWXkl;,:oxdo:;,;:oddl:collllc:::ccc:;;:c:::::::;,,,,;cd0XWMMMMMMMMMMMMNOc:dOOkxoc,,,,;dKWMMMNx;,    //
//    ,;kWMMMMMMMMMMMMMMMMMMNOl;,,;;:lcclllodololclc:;:ldO0KXXXKkl,,,;:oxdollooolc:;;:cc:;clc:cc:cccc:::cc:;,,,,,,,;cxKWMMMMMMMMMMMWKxc;,,,',,,:d0NMMMMMNx;,    //
//    ,;kWMMMMMMMMMMMMMMMMMW0o;,;:::ccclolcclooolodool:;,;;::::c::;;:coddlcclolccc:;:c::ccccccc:cclc:;,,,,,,,,,,,,,,,,cOWMMMMMMMMMMMMWN0kdooodOXWMMMMMMMNx;,    //
//    ,;xNMMMMMMMMMMMMMMMMWKo;,,;;;llc:ldclolooc:lldxdolc:;:;;:::::cclc::;;;::cllc::ccc:::;;::::;,,,,,,,,,,,,,,,,,;lxx:lKWMMMMMMMMMMMMMMMWWWWWMMMMMMMMMMNx;,    //
//    ,;kWMMMMMMMMMMMMMMMMNk:,,,;:c:cc::llodolll:cloddlc::::cccc:cllcc:;:lcclodc::cloddoc:;::;,,:clcc:;,,,,,,,,,cx0NWNx:xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd,,    //
//    ,;kNMMMMMMMMMMMMMMMNk:,,;;;clcllcclcldxocccooollcllolc::;:lollcc:;;cldxxxollddolodo:;;,,,cOXNNNX0Oxo:,,;lkXWMMWWKcc0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;,    //
//    ,;xNMMMMMMMMMMMMMMW0l,,;;;;:::cccloccooodollodddlloooc:clodxdolllc:coxxddddooddoodoc:;,,,oXWWWMMWMWNKkxOXWWWMMWWNd;dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk;,    //
//    ,;xNMMMMMMMMMMMMMW0l;;clc;,;;;::ldc;;::;cdxolllllccloc:odxxdoooddoodxxkxoolllodololc:;,,;xNWMMMMMMMMMMMMMMMMMMWWWO:lKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;,    //
//    ,;xNMMMMMMMMMMMMWKo;;oddl;,,,;:::ll::lolcllllllclooolccldxxdoooooolloddlcodolloodl;;;;,,:OWWMWWMMMMMMWMMMMMMMMWWWXl:OWMMMMMMMWX0OXWMMMMMMMMMMMMMMMNx,,    //
//    ,;xNMMMMMMMMMMMNkc;;cooooc;,,,;:;;cclocccc::cldxooolddolodddodolllcodolollc::cllol:;,,,,lKWWMMWMMMMMWWMMMMMMMWWMWNd;xWMMMMMMW0l;:kWMMMMMMMMMMMMMMMNx,,    //
//    ,;xNMMMMMMMMMMNOl;:loodxddddl:;;;;::lollclclollddoodddooooooloxolclooloddocc:cllllcc;,,,dNWWMMWWMMMMWWMMWWMMMMMWWWk:dNMMMMMMW0:';kWMMMMNXXWMMMMMMMNx,,    //
//    ,:kWMMMMMMMMWXkc,:ccldkkkdxkxoc;,;;;::llcccllccoodxolodooolllodllllooolclol:::ccclc:;,,;kWWMMMMMMMMMMWWMMMMMMWWWWWO:oXMMMMMMW0c,:OWMMN0o:ckNMMMMMMNx,,    //
//    ';xNMMMMMMMMXxc;:lodxxkO0Okxxxxol:;;;;;cc::cllllllllcoxxxxxxddxdolooollcccccccloooc:;,,c0WMMMWWMMWWMMMWWMMWWMWWWWW0:oXMMMMMMWO:'c0WW0o;,:xKWMMMMMMNx;,    //
//    ,,xNMMMMMMWKo;,:oxxxkkOOkk0Oxxkkkxlc:;,:l:;:lloccl:;cooddddxxdocclodollc:cllllolll:;,,,lKWMWWMMWWWMWWMWWMMWWMWWMWWO:lXMMMMMMWk:,lKKd:,;dKWMMMMMMMMNx;,    //
//    ,;xNMMMMMWXx;;codxkkkxxxkkOkxkkkxddxxl;,;;;;::cc:::;;codocldxoooolllccc::cdxdolll:;,,,,oXWMMWWMWWWMWWMMWNWMWWMWNWWO:oXMMMMMMNx;,ld:,,ckNMMMMMMMMMMNx;,    //
//    ,;xNMMMMN0o;,cdodkxxxxO0kkO0Oxxkkxdkkdddlc:;,;;:c::lc:::::coxooool:cooccccoodol:::,,,',oXWWMWMMMWWWMWKOXWWMWWWWWWWk:dNMMMMMMNd,,,,',l0WMMMMMMMMMMMNx;,    //
//    ,,xNMMMW0c,,:oxddxdddxOOkkkkxkkxddxxddkOxxxxdo:;;;;;:cc::clc:cccc:::ccc:lllolccc;,,,,,,oXWWWMMMMWWWMXo:kWWWWWWWWWNd:kWMMMMMMXo,,,,,;oKNWMMMMMMMMMMNx;,    //
//    ,;xNMMW0o;,:ldxddxkkkkO0OxxkxxxxdxkxxkxxkOOOOkkxdoolcc:;;;;::::cc;;;::::cl:;;;;;,,,,,,,lXWWMMWWWMMWWKl:OWWWNNWWWWOclKWMMMMMMXl,,,,,,,:d0NWMMMMMMMMNx,,    //
//    ';xNMWXx:,:lddddodkkxxxkxxOkdxkxodxkkxxddxkkkkxoodxxxkkxolc::;;::;,,;;;:::,,,;::,,,,,,,:OWWWMMWWWWWWO:lKWWWWWWWW0l:kNMMMMMMWKl,;:c:;,,,;lx0NWMMMMMNx;,    //
//    ,;xNN0d:,:oddxOkxxdxkkkO00kxkkkkkkkxxkxddxxkkOkdxkxxO0OxxkkOkxxddoc::;;;;;,,,,,,,,,,,,,,l0NWWWWMWWN0l,:x0XXXNX0xcckNMMMMMMMMXo;l0XK0kdl:;,;dXMMMMMNx;,    //
//    ,;xXOl;,:coxxkOOdloxO0kO0OkkkkkkkOOkxxxxxkOkxxkOOkkkOOkdxkO0kkkxkkkxkkdlccclllccccc:;;,,;:okkOOOkxocokxoooooooloxKWMMMMMMMMMWXKXWMMMWWNX0kdONMMMMMNx;,    //
//    ,;dOo;,coddxxxxxxxdxkkkxOOdxkOkxkO0OxxkkkkkxdxkOOO0OOkkdoxO00OOOOOOkO0Oddooodddxxkkkddddoc;,;clodxOKNWWWNXXXXXNWWMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMNx;,    //
//    ',cl;;:lddxkxxdokOxkkxooxkOOkkdkOkkkO0OkxkOOkkxkOkkk00kkxoxkOOOxxkxxOkxdooodkkxdddxxxOkxo:;,cxKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx,'    //
//    ,,;;,:cldodxdoodOOxkkddkK0Okxdxkkxxk0OxoodOO00kkxk0KK0OkkkkxxxxkkkddxxOxddddxkOkdodxxxxolc;,oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;'    //
//    ,,,;clloddxxxddkOkkOxdxOOkxdkkOOOOOOOkddxkkkOOOkk00OkkxxOOxddkkkOkxxxO0OxoodddkOkxxxddoll:,:kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;,    //
//    ,,;llodddxOkkkxooxkxdxOkxkxxxdxOOkkOOOOkOkddkOkkO00kkkkkOOOkOOkxxxxxkOOOkxkkxooxxxkxxdll:,;oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;,    //
//    ,,lxdxkxddkkxxolodxkxdxO00xdxdxxkkkkkkOO0kdxxxOOkxxkkkxxkkkOkxxO0OkxxkkkdxkOOxkkkddxdooc;,:kXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXWMMMMNx,'    //
//    ,,cdddkkxxkOOkdxkkOxxxxkOOOkkkxxkkxkkOkOOkkdldkxxxxkxdxkxdxxxdxOOO0OkxkOkxO0OOkkkxxxloxl;;oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN00XWMMMMMMMMMWKdccOWMMMNx;,    //
//    ,,codkOOOOkxdxkxxxdodddxk00OxxxxxxO0OxdkOxdxxkOkkO0kxkkkO0OOOkkkkkkOOxxOOOkkkddkOOxddol:;cOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk::OWMMMMMMMMWKl,,,xNMMMNx;,    //
//    ,,cddxkxxkdldkddxdlxOkOOkOOOxkOkxk00OxdkOxddxO0Ok0OkkxxOOkkkdxkkkkkOkOOOkkxdxkkkkOxoxo:,,oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk;:OWMMMMMMMMWO:,';xNMMMWk:,    //
//    ,,lxdxkddxdodxxdooxxdokOOOkkO0OkxkOOxoxOkdddxOOkkOkkxxxOOxkkdxOxxxxxxxkO00kxkkk0Oxdddl:,cONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk;;kWMMMMMMMMWk;,';kWMMMNx;,    //
//    ,,cdxkkkxxkkxxkkkkkxxkkk0OkkOOOkkkOkkOOOOkxxkOkxkkkkOOxkOkOkkkOOOkxxxkO0OOkxxxO0kxooo:,;dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:,dNMMMMMMMWKo,',c0WMMMNx,,    //
//    ,,cdxxxxxkxxk0kkOOOkxxxOOxkkkkOkxk0kkkk0OkOkOOOkkkkxkkxxkOkxxxkOkxxxOxxkkkO0xdxxxkkxo:,:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKl,c0WMMMMMWKo,,,;xNMMMMNx;,    //
//    ,,lddxddkkddOOkkxkkOOOkxookkkkxxxkkkOkOxxkkxdddkOOkkOkOkxkkxkkOkdddxkkxxkkkOkkOkkOkdl;;xXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk;,o0WWWWXkc,',;dXWMMMMNx;,    //
//    ,,cdkOkxOOdxOkxxkO00xdkOkkOOOkddkxx00OkxOkdxkOOO0kkOkxkxxkkO0OxddxooO0xxkodkxxxxkkkd;,l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:,:oxxo:,,,,:xNWMMMMMNx;,    //
//    ,,okkkkOOOkkkxxxOO0OkxkO0OOOO0OxkkO0kxdxOkxOOOkxxkOK0Oxxxxk0Oxxxkxxk00kkxxxkxxxxxkkl;:kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxl:;,,,;:lx0WMMMMMMMNx;,    //
//    ,,cdkkxdoxkkooxkkkkO0OkkkkO0kxOOkOOOkxdxkkOOkkdodxOO0OkxkOOkkkxxxddkOxxkOxdxxxkkddo:,lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0OOO0XNWMMMMMMMMMNx;,    //
//    ,,:dxdxxxkOkxxxxkkxk00kkxxk0xdxdooxOkxkkOO00OOkxxkxxxxOOkkkkk00kddxkxox0OxxxxxOOdol,;dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;'    //
//    ,,cddoxkkkOOkkkxxkkOOOO0OkOOxodxxdkkkkxdOOkxxkkxxOkxxk00OkxxkOOkxOkxdxxxOOxddxkkddc,:xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:,    //
//    ,;oxoodxkxkOkxxxxkkkkxxOOkxkxxkxxxddkkxOOkxxkxddkkdxkkOOOOxdxkxxO0xxkxxkOxxxdoxkxl;,cONWMWWWWWWWWWWWWWWWMMMWWWWWWWWWWWMMWWWWWWWMMMWWWMMMMMMMMMMMWWW0c,    //
//    ,;cc:::cc::cc::::c::cc:ccc:::cc::c:cllllccccc::llcc:::c::c:::c:clc:cccccc::::;:c:;,,;lodddoooooooddoooodxddoooooooooodddoooooodddddodddddxxxdddddooc;,    //
//    ;,,,,,,,,,,',,,,,,,,,,,,,,,,,,,,',,,,,,''',,',,',,,,,,,,,,,,,,,,,,,,,,,,,',,,,,,,,,,,,,,,',,,,,,,,,,,',,,,,,,,,,,,,,,,,,,,,,,,,''',,,,,,,,,,,,,,,,,,,;    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ZOKU is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
