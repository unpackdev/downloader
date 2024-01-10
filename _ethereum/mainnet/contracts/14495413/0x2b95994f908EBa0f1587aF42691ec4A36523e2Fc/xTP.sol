
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TRASHPUNKS G2
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNXKK000OOOOOOOkkkOOO000KKXNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWNXKOkdoolc:;,,''.......'''........'',,;::clodkOKXNWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNOdc;,...............'',,,,,,,,,,,,,,''''''''''''',;:loxOKNWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWXx:................',,,,,,,,,,,,,,,,,,,,,,,,,,,,'',,,;;;;;;:ldONMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMW0:..................''',,,,,,,,,,,,,,,,,,,,,,,,''',,,,;;;;::::;:oKWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMKc....................''''''''''',,,',,,,,,'''',,'',,,,,,;;::cc:::dXMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWk;.....'''........''',,,,,,,,,,,,,,,,,;;;;;,,,,;;;;;:::;;::::cc:::cOWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMXo,'''..'...'',,,,,;;;;;:::::::::::::::::::::::;;::::::;;;;;:::;;;oKWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWKo:;,'''''..'''',,,,,,,,;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,;;;;;lONMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWkc;;,,,,;;;;;,,,,,,,,,,,;;;;;;;;;;;;;;,,;;;;;;;;;;;;,,,,;;;::;lKWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNx::;,,,',,,,,,,,,,,,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,;:ccclkNMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWKo::;;,,,,,,,,,,,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,;;;;;;:::::::cxXMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWOl:;;;;;,,,,,'''''',,,,,,,,,;;;;;;;;;;;;;,,;;;;;;;;;;;;;;;;,,,,cOWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWKdc;;,,,,,,,,,,,,,,,,,,,;;;;;;;;:::::::;;;;;;;;;;;,,,,,,,,,,,,:dKWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWKdl:;,''''''''',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;loxXWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMXOxoc;,'............'''''',,,,,,,,,,,,,,,,,,,,,,,,;;;;;;:cc::cooxXWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNKKxc;,'.................',;::;;::::;;:::ccc:::cllllllccllc::lookXMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNkc;,''................',;ccclooolccloooddlclooooolllcllc::looONMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNkc;;,'................',;clclodolccolloddlclooooollllllc:clodONMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNkc;;,'................',:lllldoolclollodocclloooolllcllc:cood0WMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWOl:;,'................',;cllloollcloclodocclloooolccclcc:cood0WMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMW0l:;,'................',;clcloolccloccodoccllooollccclcc:coldKWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWKo:;,'.................,;cccloolccllccodoccllooollccclcc:colxXMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMXxc:;'.................';ccccoolccllllodocclloooolccclcc:lookNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMNkl:;,'................',:cccllcccllllodocclooooolccclccclloONMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWOo:;,'................',:::cllc:cllllodlcclooooolccllccclod0WMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMW0oc:,'..'.............'';::clc:::llllodocclooddolccllccclodKWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWKdc:;'..'..............',;::cc:::llclodocllodddolclllccloodKWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWKxlc;,..'...............,;;:cc:::clclodocloodddolllollllooxXMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMXklc;,'.'...............',;;:::::cc:lodocloddxxdllooolloookXMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNOoc:,'.'...............',,,:::::cc:lodlcloddxxdloodolloooONMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMW0dl:;'.'...'...........',,,;::::cccloolcodddxxdooddoloood0WMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWKdlc;'''...'...........',,',;;;;:cclooccodddxkdooddooooodKWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWKxlc;,''...'...........',,',;;;;;:clloccodddxkdodddoooooxXWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWXxoc:,'''..'...........',''',,,,;::cllccooodxxdodddoooookXMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNkoc:,'''..'...........',,'',,,',;::cl::loodxxdooddlooookNMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMN0dlc;'''.''...........',,'',,'',;;::c::looodxolodolooodONMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMW0dlc;,''.''...'.......',,',,,''',;;::::clloddoloooloood0WMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWKxlc:,''.'''..........',,',,,''',,;;:;;:clloolclllcllodKWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWXxlc:,''.'''..'.......',,',,,''',,,;:;;:cclllc::cccclldKWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWXxlc:,,'''''..''......,,,,,,,,'',,,;;;;::ccc::;;:::cllxKWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMXklc:;,'''''..''...'..,,,,,,,,'',,,,;;;;;:;;;;,,;::cloxXWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWNOxoc:,''.''..''...'.',;,,,;;,,,,,,,;;,,,;,,,,,,;:coxxkXWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWNKOkxoc;,'''..''...'.',;,,;;;,,,,,,,,,,,,;;;;;;:ldxkkk0NMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWN0Okkxdlc:;,,,''.'''',;;,;;;,,,,,,,;;;;::cclodxxxxxkKNMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWX0Okkkkxxdoolccc::::cc::cc::ccccllooddxxkkxxdooxKNWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWNX0kxxxxxkkxkkxxxxxxxxxxxxxxxxxxxxddoolllodOKNMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKOkxdoollllooooooooolllccc:::::codk0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNK0OkxxdoooollllllooodxkO0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWNNNNNNNNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract xTP is ERC721Creator {
    constructor() ERC721Creator("TRASHPUNKS G2", "xTP") {}
}
