
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LOL™️ | THE RETURN
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    LOL™️ | THE RETURN | DUST MONKEY                                                                                            //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMMMMMMMMMMMMMNK000000KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xdolcckNMMMMMMMMMMMMMWx;,,,,;;:coxOKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKkdc;'......:KMMMMMMMMMMMMMNo,,,,,,,,,,,;:okKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOo:'...........;OMMMMMMMMMMMMMXl,,,,,,,,,,,;;;;cokXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl;..............';OMMMMMMMMMMMMMKc',,,,,,,,,,,;;;;;:lx0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0d;..............'',,;xWMMMMMMMMMMMM0:',,,,'',,,,,,;;;;:::cd0NMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l,................',,,,dNMMMMMMMMMMMWk;',,,''',,,,,,,,;;;::::cdKWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMW0o,..................',,,'lXMMMMMMMMMMMNd,,,,,,',,,,,,,,,,;;;;;:::lkNMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMXx,....................''',';0MMMMMMMMMMM0c'',,,,,,,',,,'',,;;;;:::::cdKMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMW0c'.....................'...',kWMMMMMMMMMWx,'',,,,,,,,,,,',,,,,;;;::::::oKWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWk;.............'''''.'''.''''''dWMMMMMMMMMXo,,',,,,,,,,,,,',,,,,,;;;;;::::o0WMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNx,...................'.''''''','lXMMMMMMMMMKc,,,,,,,,,,,,,,,,,,,,,,;;;;:::::oKMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWNd,..............'.....''',,,,,,,,c0WWWWWWWMMO;,,,,,,'',,,;;;;;,;;;;;;;;;::::::dXWWWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMWX0kdoolldxolllcccclllcccc:;,'.'''',cllllllloxkkkOOOO0Kx;,,,,,,,',,,;:cclloooooollcc::::::cloodxk0XNMMMMMMMMMM    //
//    MMMMMMWNOdc;'.''''':ddddddddddddddddddol;'''';ldddddddddddddddddddl:;,;;;,,,;cloddddddddddddddol::;,,,'',,;:cox0NWMMMMMM    //
//    MMMMWKd:'.''''''''':ddddddddddddddddddddo:,,,;oddddddddddxxdddddddddl:;;,,;codddddddddddddddddddol;''''''',,,,;:lkKWMMMM    //
//    MMMXd;.....'''''''':odddddol:::ccldddddddc,,,;ldddddddooxkkkxxdddddddl;,,;codddddddoolllooddddddddl;'''''',,,,,;;;cxXMMM    //
//    MW0:.....''''''''',:odddddo;....':oddddddc,',;lddddddl;:OWWNXKxddddddo:,;coddddddoc:;,;;;:codddddddc,,,,,,,,,,,,,,;:o0WM    //
//    WO;.....''''''',,,,codddddolcccccodddddol;'',;lddddddl;;kWWNNKkddddddo:;:oddddddoc;,;;;;;;;coddddddo:;,;;;,,,,,,,,;;;l0W    //
//    Kc.....'''',,,;;;;;cddddddddddddddddddol;,''';oddddddolldOOkkxdddddddc;;coddddddl:;;;;;;;;;;ldddddddl:;;;;,;;,,;;;;;;;lK    //
//    d'..'''''',;;;;::;;cddddddddddddddddddddo:,,,;oddddddddddddddddddddoc;;;coddddddo:;;;;;;;;;;ldddddddl;;;,,;;;,;;,;;;;;;x    //
//    c..'''''',,;;;;;;;;cddddddoc;;;:::lddddddoc,,:oddddddddddddddddddol::;;;:odddddddl:;;:::;;;coddddddoc;;;,',,;;;;;;;;;;,l    //
//    :..''''''',,,,,,,,,cddddddo:'''',,:oddddddl;,:odddddddlloddddddddoc:;;;;;:odddddddoc:::::clddddddddc;;;,,',,;;;;;;;;;,,c    //
//    c..'''''',,;;,,,,,,:dddddddollllooddddddddl;;:oddddddo:,:oddddddddoc:;;;;;codddddddddooodddddddddoc;,,,,,',,;;;;:;;;;,,l    //
//    d'.''''',,,,,;;,,,,cdddddddddddddddddddddl:,;:oddddddo:;;dOxddddddddlc:::::codddddddddddddddddddl:;,,,,',,;;;;::;;;;;,,x    //
//    Kc.'''',,,,;;;;;;;;lddddddddddddddddddolc;,,;:oddddddo:;;dXKOkxddddddoc:::::ccoodddddddddddddol:;;;;;;;;;:::::::;;;;;,lK    //
//    WO:''''',,,,;;;;;;:cllllccccccccccccc::;,;;;;:cllllllc:;;oKNNX0xllloolc:::ccccccclllooollllc:;;,;;;;;;:::::::::;;;;,,c0W    //
//    MWO:'''',,,,;;;;;;;cloolllc;''''',:clllllllc;,:llllolllllokOkkkdllool:::loooooolc::::::;:lllllllc;;;;;;::::::;;;;;,,l0WM    //
//    MMWXd;''''',,;;;;;;lddddddd:'.'';coddddddoc;;;cdddddddddddddddddddddl::codddddddol::;;;;:oddddddl;,;;;;;;;;;;;;;,,:xXMMM    //
//    MMMMWKd;'''',,,,,;;cddddddd:'.,:odddddddl:,,,;cdddddddddddddddddddddl::codddddddddl:;;;,:oddddddl;,,,;;;;;,,,,,,cxKWMMMM    //
//    MMMMMMWXko:,''''',,cddddddd:,;ldddddddo:;,,,,;cdddddddoolldOOOxoooolc::coddddddddddoc;,,:oddddddl,'''',,,,',:ld0NMMMMMMM    //
//    MMMMMMMMMWNKOxdllccodddddddlcoddddddoc;,,,,,,,cdddddddc;;;xNNXx:::::::::oddddddddddddl;,:oddddddxxdooooodxk0XWMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWWWN0xddddddddddddddc;,',,',,,,cdddddddoolodkkkdloolc:::codddddddddddddoc:oddddddONMMMWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMW0xddddddddddddddc,''''',,,;cdddddddddddddddddddoc:;;:odddddddddddddddooddddddONMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMW0xdddddddddddddddl;''',,,,,cdddddddddddddddddddo:;;;;lddddddoloddddddddddddddONMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMW0xddddddddxdddddddo:,''''',cdddddddoccclk0Oo::c:;,,,;lddddddl;;coddddddddddddONMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMW0xddddddx0KOxddddddoc,'''',cdddddddc;;;cON0l,,,,;,'';lddddddl;',:odddddddddddONMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMW0xdddddx0NWN0xdddddddl;'',,cdddddddoooooxkxdoooooc,',lddddddl;;ldOOxdddddddddONMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMW0xdddddx0WMMWKkdddddddl:,',cdddddddddddddddddddddc'',lddddddxOKWMMWKkddddddddONMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWKxdddddx0WMMMWXOdddddddoc;,cdddddddddddddddddddddc'';lddddddkXWMMMMWX0xddddddOWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMNK000000NMMMMMWNK0000000Ox:;:::::::::::cccccccccc:,',:ccdk00KNMMMMMMMWX000000XWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMWWXkl,.............''',,,,,,,,,,,,',;lkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXx:'...'''.........'',,,,,,,,,,,;;,,,,;:d0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;'.',,;,'........'''''',,,,,,,,,;;;;,,,,,:d0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;...',;;;,'........'''''',,,,;;;,,,,,,,,,,,,;:o0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd,...',;;,,'..........''''''',,,;;;;;,,'''''',,,,;:o0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd;...'',;;,',,'..........'''''',,,,,;;;,,';;'.'',,,;;:cd0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:...'',;;,'':Ok;........'''''''',,,,;;;;,,'o0l'..',,,,;;;:xXMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMXo'...',,;;,''lKXo'.........'''''',,,,,,,,,,,':0Nx,..''',,;;;;l0WMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMKc....',;;,'';dNWO;..........'''''',,,,,,,,,,,',dNWO:...',,;;;;;cOWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMM0:....',;;,''cOWMXl'.........'''''''',,,,,,,,,,,':0MMXo'..'',;;,,,:kWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMKc...',,;;,.,oXMMWk,..........'''''',,,,,,,,,,,,,''dNMMNx;..'',;;;,,:OWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWd'...';;,'';xNMMMNo'..........''''',,,,,,,,,,,,,,,':0MMMW0c'.'',;;,,,lXMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMK:...',,,''c0WMMMMKc...........'''',,,,,,,;,,,,,,,'',kWMMMMXo,..',;;,';kWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMk,..',,'.;xNMMMMMMO;..........'''',,,,;;;,,,,,,,'''''dWMMMMMWOc'.',;;,'dNMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMk,.','',oKWMMMMMMMk,..........'''',,;;;;;;;,,,,,,''''oNMMMMMMMNx;.',;;,dNMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMM0;.',''oNMMMMMMMMMk'..........'''',;;;;;;;;,,,,,'''..oNMMMMMMMMWk,.',,,xWMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LOLtm is ERC721Creator {
    constructor() ERC721Creator(unicode"LOL™️ | THE RETURN", "LOLtm") {}
}
