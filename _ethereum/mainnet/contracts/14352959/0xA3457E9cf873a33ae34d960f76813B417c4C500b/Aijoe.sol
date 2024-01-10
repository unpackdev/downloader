
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A.I.Joe
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    AiJoeMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd:;;;;;;;;;;;;;;;;;;;,;:::ccloodddooollcc:::,'    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0d:;;;;;;;;;;;;;;;;;;::cclooddddddoollc:::,''    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0o:;;;;;;;;;;;,;;::ccloodddxxddoolcc::;,'',    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOl;;;;;;;;;,;::clloddxxxxxddoolcc::;,'',,    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo:;;;;,;;::ccloddxxxxxxddollc:::;,,',,,    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKXWMMMXd:;,,;;:cclodxxkkkkxxdoolcc::;;co;',,,    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKkdlcokKWMMMMKl,,;::clodxxkkkkkxxdolcc:::;:d0d,,,,,    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0dc,''ckNMMMMMMNk:;::cclodxkkkkkkxdollc:::;;lONO:,,,,,    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0o;''',oXMMMMMMMKo:;::cllodxkkkkxxddolc::::;:xXWXo,,,,,,    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;'''';xNMMMMMMW0l;::ccloodxxkkxxddollcc::;:oKWMWx;,,,,,,    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNWWMMMMMMMMMMMMMMMMMMMMMMMMNKk:,,,,,;dNMMMMMMWOc;::cclooddxxxxddolcc:::;;l0WMMW0:',,,,''    //
//    MMMMMMMMMMMMMMMMMMMMMMWNKOkxddoooodxkKNWMMMMMMMMMMMMMMMMMWKo;,',,,,,oXMMMMMMWOc;::cclooddddddoollc:::;,,lKMMMMXo,',,,,,;    //
//    MMMMMMMMMMMMMMMMMMMWXOxlccloooollc::;:ld0NMMMMMMMMMMMMMMW0c,'',,,,':0WMMMMMW0c;::ccloodddoooolcc:::;;,;;c0MMMNx;'',,,';x    //
//    MMMMMMMMMMMMMMMMMNOdc::cloddxxxdddolcc:;:lkXWMMMMMMMMMMMKl,',,,,,,,dNMMMMMMKl;::cclodddoollccc::;;,;;;;;:kWMXd;''',,,;xN    //
//    MMMMMMMMMMMMMMWXOo:;:::cloodxxxxxxxxdolc:;;ckNMMMMMMMMMWk;',,,,,,':OWMMMMMNd;:::cloooollccc:::;;;;;;;;;;;xN0l,''''',:kNW    //
//    MMMMMMMMMMMMMNkl;;;;:::::ccloddxxxxxxxdolc:;:oKWMMMMMMMNo,',,,,,,,lXMMMMMWk:;::clooolcc::::;;;;;::::::;;;od;'..''',c0NXk    //
//    MMMMMMMMMMMW0l,'';lk00OOkdlccloodxxxxxxxdolc:;ckNMMMMMMNo',,,,,,,,dWMMMMMXo;::cllollc:::;;;;;;:::clllc:;,''......,dXXkc,    //
//    MMMMMMMMMMNk;..,l0NMMMMMMWN0xlccloddxxxxxxdlc:;:dKWMMMMNd,,,,,,,,,xWMMMMWk:::cclllcc::::;;;;:::clodddlc;,'.....'cON0o;,,    //
//    MMMMMMMMMNx,..:kNMMMMMMMMMMMWKxl:clodxxxxxxdol:;;c0WMMMWk;',,,,,,,xWMMMMNd;::cclcc::lx0x:;;;:::codkkxoc;'....':xXKx:,,,,    //
//    MMMMMMMMWx,..c0WMMMMMMMMMMMMMMWKd::clddxxxxxxdl::;cOWMMMXl,,,,,,,,dNMMMMKl;:::c:::cxXWWx;;;;:::coxkkdl:,'..':xKXkc,,,,,,    //
//    MMMMMMMM0;..:0MMMMMMMMMMMMMMMMMMNOl:cloddxxxxxol:;;c0WMMWO:',,,,,,oXMMMM0c;::::::o0WMMKl;;;;:::ldxkxoc;'',lkXXkc,,,,,,,,    //
//    MMMMMMMNd'.:OWMMMMMMMMMMMMMMMMMMMWKd::cloddxxxdoc:;;l0WMMWk:'',,,'c0MMMMO:;:::;cxNMMNOc;;;;:::cldxxdl:,;o0NXkc,,,,,,,,,,    //
//    MMMMMMMK:.,kWMMMMMMMMMMMMMMMMMMMMMMNkc::loddddddlc:;;lKMMMWkc;,,,,;OWMMWk;;::;cOWMWKo,,;;;:;::loddol::dKNKd:,,,,,,,,,,,,    //
//    MMMMMMWk,'oNMMMMMMMMMMMMMMMMMMMMMMMMWOl::cooddddolc:;;dNMMMX0o,,,,,xWMMWx;;:;cOWMNx:',;;:::::coddol:;dKOo:,,,,,,,,,,,',,    //
//    MMMMMMWk,;OMMMMMMMMMMMMMMMMMMMMMMMMMMWKo::cloodddoc:;;cOWMMMW0:',,,dNMMWd,;:;dNWKl'',;;:::::clddol:;:oc,,,,,,,,,,,,,,:ox    //
//    MMMMMMWk,lXMMMMMMMMMMMMMMMMMMMMMMMMMMMWXd::clloddolc:;;dNMMMMXo,,,,oXMMNo,;;:OWO:''';;:::::clodol:,',,,,,,,,,',',;cxOXWM    //
//    MMMMMMMk;xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXx:::clooolc::;c0MMMMWx,,,'lKMMKc,;,c0O:''';;;::::cooooc:,'',,,,'''',',cd0NWMMMM    //
//    MMMMMMMOckMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx:;:cclolc::;:kWMMMWk;,,':0MWk;,,,oOl'',;;;:::clooolc;,'''''''''',:dOXWMMMMMMM    //
//    MMMMMMM0lOMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd:::ccllcc:;;dNMMMWk;',';kWXl',,,lo,',;;::::cloooc:;,'''''''',:oOXWMMMMMMMMMM    //
//    MMMMMMMKlkWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd:::cclcc:;;lKMMMWd,,,';kNx;'''','',;::::clloolc;,,''''''';lOXWMMMMMMMMMMMMM    //
//    MMMMMMMKloXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKo;::cccc::;c0MMMXo'''':OO:''''.',;;:::clllllc;,''''''.':dKWMMMMMMMMMMMMMMMM    //
//    MMMMMMMXl,dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOc;::ccc::;:OWMWO:'''':dc'''.'';;:::cclllc:;,'......':dXWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMXl',dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd;:::c:::;:kWXOl''''',,''.'',;:::::cccc:;''.......;dXWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMNo'',xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk:;:::::;;;kXd;,.''..''.',;;:::::::::;,''.......,lKWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMWk,''oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0c;;:::;;;;ll,........',;:ccc:::;;;;,'........'cONMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMXo,,dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo;::;:;;;,'.......'',;cclllc::;;;,'.........;xXMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMKl:kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo;;::;;;;,'.....',;:ccllllc::;;,'.......'''':dxxxkkO0KXNWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMNKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKl;;:::;;;,..''',;:cclllcc::;;,''''',,,,;;;;;;;;;;;;;::clodkOKNWMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk:;;:::;;;,',,;;::clllcc::;;;,,,;;;;:::::ccccccccccccc:::;;;;:ldOXWMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl;;;;;;;;;;;;:::ccllcc:::;;;;;;::::::ccccllllllllllllllccc::::;;;cdONWMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOdc;;;;;;;;;;;;:::ccccc:::::;;;:::::cccccccccccccccccccccccccccccc::;;;lONMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l;,;;;;;;;;;;;;:::cccc:::::::;;:::::ccccccc:::::::::::::::::::ccclllcc:;;;oKWM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOc,,;;;;;;;;;;;:::cccc::::::::;;:::::::::::::;;;;;::ccccc:;;;;:::::clllllc:;;l0W    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk:,,,;;;;;;;;::::::::::::::::::::::;;;;;;;;;;:coxk0KXXNNXXK0kdc:;;:::cclooolc:;oX    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo,,;;;;;;;;;;;::::::::::::::::::::;;;;;;;;;:o0XWMMMMMMMMMMMMMWN0dc;;:::clooolc::k    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkc;;;;;;;;;;;;;;;;::::::::::::::::;;;;;;;;;lONMMMMMMMMMMMMMMMMMMMWKd:;;::clloolc:c    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWW0o;,,,,;;;;;;;;;;;;;;;;::::::::::::;;;,,''',lKWMMMMMMMMMMMMMMMMMMMMMMWOl;;;:clloolc:    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWX0kxdddol:,,,,;;;;;;;;;;,,,,;;;;;;;;;;;;;;;::;,''...'kWMMMMMMMMMMMMMMMMMMMMMMMMMKl;;;:cllool:    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMXkl:;;;;;;:::::::::::::::::;;;;,,,,,,;;;;;;;;:;'..    '0MMMMMMMMMMMMMMMMMMMMMMMMMMWKl;;;:cclllc    //
//    MMMMMMMMMMMMMMMMMMMMMMMNOl;;;;::::::::::::::::::::::::::::;;;,,,,,;;;;,''.    .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:;;::ccccc    //
//    MMMMMMMMMMMMMMMMMMMMMWKd:;;:;::::::::::cccccccclccccccc::::::::;;,,,;;,...   'dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo;;;::::::    //
//    MMMMMMMMMMMMMMMMMMMMNkc;;;;;::::::::ccccllllooodooolllllccc:::::::;,,,,,'.':xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk:;;;:::::    //
//    MMMMMMMMMMMMMMMMMMWKo;;;;;:::::::::cclllooodxxkkxxdddooolllccc::::::;,,,,:xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0c,;;:::::    //
//    MMMMMMMMMMMMMMMMMNkc;;;;;:::::::ccclllooddxkkOkkkxxxxdddooolllcc::::::;,,dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl,;;:::::    //
//    MMMMMMMMMMMMMMMMXd:;;;;;::::::ccccllloodxkkkkkxxxxxxxdddddoolllcc::::::;;:kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd,;;:::::    //
//    MMMMMMMMMMMMMMMKo;;;;;;;:::::ccclllloddxkkkkxxdddddddddddooolllcc::::::::;;dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd;;;::::;    //
//    MMMMMMMMMMMMMW0l;;;;;;;;::::cccllloodxkkkkkxxxddddddddddooolllccc:::::::::;;dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd;;;:::::    //
//    MMMMMMMMMMMMW0c;;;;;;;;:::::ccllloodxkkkkxxxxxxddddddoooolllcccc:::::::::::;;xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd;;;::::l    //
//    MMMMMMMMMMMMKc,;;;;;;;;:::::cclllodxkkkxxxxxxxxxdddddoolllcccc::::::::::::;:;c0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo;;;;:::k    //
//    MMMMMMMMMMMKl,;;;;;;;;::::::clloodxkkxxxxxxxxxxxdddooollccc::::::::::::;;;;;,:OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0c;;;;:;oK    //
//    MMMMMMMMMMNd;;;;;;;;;;;::::ccloodxkkkxxxxxxxxxddddoollccc:::::::::::;;;;;;;,;dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;;;;;;cOW    //
//    MMMMMMMMMWO:,;;;;;;;;:::::ccllodxkkkxxxxxxxxddddooollcc:::::::::;;;;;;;;,,;o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c,;;;;:xNM    //
//    MMMMMMMMMKl,;;;;;;;;;:::::cllodxkkxxxxxxxxdddddoollccc::::::::;;;;;;;,,,cxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo,;;;;:dXMM    //
//    MMMMMMMMWx;;;;;;;;;;;::::ccloodxxxxxxxxxddddddoollcc:::::::;;;;;;;;,,;lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;,;;;:dXMMM    //
//    MMMMMMMMNo,;;;;;;;;:::::ccllodxxxxxxxxxddddddoollcc::::::;;;;;;;;,,;l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOc,;;;:oKMMMM    //
//    MMMMMMMMKl,;;;;;;;::::::ccloodxxxddddddddddooollccc:::::;;;;;;;,,,lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl,;;;:dXWMMMM    //
//    MMMMMMMMO:,;;;;;;;;::::ccloodxxxxxxddddddooolllccc::::;;;;;;;;,,ckNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd;;;;:xXMMMMMM    //
//    MMMMMMMMk;;;;;;;;;;::::cloodxxxxxxxxddddooollccc::::;;;;;;;,,,;oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx:,;;ckNMMMMMMM    //
//    MMMMMMMWx;;;;;;;;;;:::ccloddxxxxxxxxdddoolllccc::::;;;;;;,,,,cOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:,,;cOWMMMMMMMM    //
//    MMMMMMMNd,;;;;;;;;;:::clooddxxxxxxxxdddoolccc:::::;;;;;;,,;dOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOc,,;oKWMMMMMMMMM    //
//    MMMMMMMNd,;;;;;;;;:::cclooddxxxxxxxdddoollcc::::;;;;;;;,,;xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOc,,:xXMMMMMMMMMMM    //
//    MMMMMMMWx,;;;;;;;;:::cclooddxxddddddddollcc::::;;;;;;;,,;xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:,,cONMMMMMMMMMMMM    //
//    MMMMMMMWk;,;;;;;;;:::ccloodddddddddddoollc::::;;;;;;;,,;kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:,;oKWMMMMMMMMMMMMM    //
//    MMMMMMMM0:,;;;;;;;:::ccloodddddddddooollcc:::;;;;;;;,,;kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXd;,:kNMMMMMMMMMMMMMMM    //
//    MMMMMMMMXo,;;;;;;;:::ccloooddddooooooolcc::::;;;;;;,,;xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNOc,,l0WMMMMMMMMMMMMMMMM    //
//    MMMMMMMMWO:,;;;;;;:::cclloodddddddooollcc:::;;;;;;;,,dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNOo;,,c0WMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMNo,;;;;;;;:::cclooddddddddoollcc::;;;;;;;,,oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkl:;,,:OWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMM0c,;;;;;;:::cclloddddddddoollcc::;;;;;;;,lKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkoc;;;;,;dNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMNd;;;;;;;;:::cclooddddddooollcc::;;;;;;,:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKkoc:;:;;;;;:OWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMKl,;;;;;;;:::ccllooooooooollcc::;;;;;,;dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0xo:;:::::::;;;c0MMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWO:;;;;;;;::::cclllooooooollcc::;;;;;,lKMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkl:;:ccccccc:::;;:OWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMNx;;;;;;;;::::cclloooddooolcc::;;;;,;xWMMMMMMMMMMMMMMMMMMMMMMMMMMN0d:;::clloollcc:::;;;xWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMXd;;;;;;;:::::cclooddddoolcc::;;;;,:0MMMMMMMMMMMMMMMMMMMMMMMMMW0o:;::cloooollc::::;;;;dNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMXo;;;;;;;:::::clloddddoolcc::;;;,';OMMMMMMMMMMMMMMMMMMMMMMMWKd:;::clooooolcc:::::;;;;oXMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMKl;;;;;;;;:::ccllooooollcc:;;;;,',xWMMMMMMMMMMMMMMMMMMMMMNkc;::clloooollc:::::::;;;,oXMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMM0l;;;;;;;::::cclllllllcc::;;;;'',oXMMMMMMMMMMMMMMMMMMMWKo:;:cclooooollc::::::::;;;,oXMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMW0c,;;;;;;::::ccccccccc:::;;;,'',;dNMMMMMMMMMMMMMMMMMMKl;:cclloodoolcc::::::::;;;;,oNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMW0c,;;;;;;::::::cccc:::::;;;,'',,;dXMMMMMMMMMMMMMMMMKl;:clloodddolcc:::::::::;;;,,xWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWO:,;;;;;;:::::::::::::;;;;,',,;;;oKWMMMMMMMMMMMMMNd;:clooodddollc::::::::::;;;,;OMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWO:,;;;;;;;:::::::::::;;;;,',,;;;;cONMMMMMMMMMMMWO:;cloooddxdolc::::::::::::;;'cXMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWOc,;;;;;;;:::::::::::;;;,',,;;;:;:dKWMMMMMMMMMNo;:cloodxxdolc::::::::::::;;,,xWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMW0l,;;;;;;;::::::::::;;;,',,;;:::;;ckNMMMMMMMM0c;cloooxkdolc:::::::::::::;,,oXMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMO:',;;;;;;::::::::;;;;,',,;;:::::;;oXWMMMMMWO::clooxkxdlc:::::::::::::;,,lKMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMXl',,;;;;;;;:::::::;;;;,',;;::::::;;xNWMMMMWk::llodxkdolc::::::::::::;,,lXMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWk;,,,;;;;;;;::::::;;;;,',;;::::::;:kNWMMMMWk::loodxxdolc::::::::::;;',dNMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMKc,,,,,;;;;;;;::::;;;;,',;;;;::::;lKWMMMMMWO::clodddolc::::::::::;,'cOWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWx;,;;,,;;;;;;;;:;;;;;;,,;;;;;;;;c0WMMMMMMM0c:cloooollc:::::::;;,':xXMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMKc,;;;,,;;;;;;;;;;;;;;,',,;;;;;cOWMMMMMMMMKl:clllllcc:::::;;,,,ckXWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWk;,;:;;,,;;;;;;;;;;;;;,,,,,;,c0WMMMMMMMMMXo;cccccc::::;;,,;lxKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNx;;;:;;,,;;;;;;;;;;;;,,,,,,;kWMMMMMMMMMMWx::::::::;,,;cokKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMNOc,;:;;,,,;;;;;;;;;;,,,,,,oXMMMMMMMMMMMMKl;;;;,;;cokKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd:;;;;;,,,,;;;;;;;;,',,:OWMMMMMMMMMMMMWKkxxxk0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkl:,,,,,,,,;;;;;;,'',lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxoc:,,,,,;;;;,,',dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxo:;,;;;,,''dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKkdc;,,,,dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKx:'',xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Aijoe is ERC721Creator {
    constructor() ERC721Creator("A.I.Joe", "Aijoe") {}
}
