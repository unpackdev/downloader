
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The PEPEstocracy
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    MMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMWNK0000KXNWMMWMWNOdc:;,;;:cldkKNMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWWMWMN0xol::::::clodkOkdc;;:ccclclc::;:ld0NMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMNKOko;..';::cccllc;'.....''',,,;;;;;:clc;;ckNMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWXOdc;,,,,;;;;;;:c:,'....',;;;::ccccc::;;;;:ccc:;lKMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMN0ko:'.''',,,;;;;;;,,'.',,;::;,,,,,,;;;;:ccccc::cccc;;OWMMMMMMMM    //
//    MMMMMMMMMMMMMMMKc,:loddxxxxxddol:'. .cdO0KKK0K00Okxdo:,',;:cccccccccc;;OWMMMMMMM    //
//    MMMMMMMMMMMMMMNo:kXWXd;,;lKWWMWNKo.;ONMNKx:'';oKWMMWWXOdolcc::cccccccc,lNMMMMMMM    //
//    MMMMMMMMMMMMMM0o0MWK:     ,0MMMMWd:KWMWd.. ..  .kWMMMMMMWXkc':cccccccl;'dNMMMMMM    //
//    MMMMMMMMMMMMMMOlKMWK,.c;  .kMMMMNloWMMWo  ,kl   :NMWMMWXxc;;:cccccccccc;;l0WWMMM    //
//    MMMMMMMMMMMMMMXdkWWWO:,,',dNWWXOo.,0MMMKd:...  .kWMWWKd:;;:cccccccccccccc::xXMMM    //
//    MMMMMMMMMMMMMMMKlcxOOkdxxxxddl:;,..,d0NWWNKkxdx0X0kdl:,;;;ccccccccccccccccc:lKMM    //
//    MMMMMMMMMMMMMMMW0l;'....'',,;:,'';:;.'codddxdool:;'',;;:cccccccccccccccccccc;lXM    //
//    MMMMMMMMMMMMMMMMWW0:.  ..',,''';ccccc:;,''''',;;;;;;::;,,,;:cccccccccccccccl:;OM    //
//    MMMMMMMMMMMMMMMMWKo;;:;;,,,..,cccccccccc:;,''',,,;;,,,,;;ccccccccc:ccccccccl:,xM    //
//    MMMMMMMMMMMMMMMWO:;cccccccc;:ccccccccccccccccccccccccccccc:;;;,,,::,;cccccccc,dW    //
//    MMMMMMMMMMMMMMWO;.,;:cccccccccccccccccccccccccccccc::;;;;;,,,;::;,;:;:ccccccc,lN    //
//    MMMMMMMMMMMMMMWOl:,,;;;;;;:::cccccccccccc:::;;;;;;;,,,;;:::;,';:c;':ccccccccc,lN    //
//    MMMMMMMMMMMMMWMWKxoo:,,,,;;;;;;;;;;;;;;;;;;;;;;::::::;,,,,,'..;:;,;cccccccccc,cX    //
//    MMMMMMMMMMMMWXklcdKXl'''',::::;,,,,,;;;;;;;;,,,,,,;,,,,,,,,,;:;,;:ccccccccccc,lN    //
//    MMMMMMMMMMWXkdlo0Xxc:;;cokOOkko'..''''''',,,,''.'',''''',,::;;;:cccccccccccc::0W    //
//    MMMMMMMMMW0dxdkNNo;c,,d00OOO0O:.;;;;;;;;,,'',:lodol;.',:c;;;;ccccccccccccc::dXWM    //
//    MMMMMMMMM0o0xoNMXl,:;;cooxkOO0xc,.'''...',:lodolc;;;::;,;;:cccccccccccc::lxKWWMM    //
//    MMMMMMMMXdkWdoWWWXx:;::;;::clloo:'.....,;::;;;;:c:;,,,;:ccccccccccccc:cokXWWWMMM    //
//    MMMMMMMWxdNM0xkkkkkc''',,,,,;;,,'',;::cccc::;;,,,,,;:cccccccccccc::ldkXWMMMMMMMM    //
//    MMMMMWKxxKMN0OKXKK00KKKKK00OO00Okxdl:'.';;;;;;;:ccccccccccccc::cldOXWMMMMMMMMMMM    //
//    MMMMXxd0NWNdcdKWWWWWMMMMWMXx0MWMWWMMN0l'.,clcccccccccc:::::codkKNMMWMMMMMMMMMMMM    //
//    MMMKoxNWWWd,xNWN00NMWKk0WMKlkMNxd0NMWWW0d:.,::cllloooddxkO0XWMMMMMMMMMMMMMMMMMMM    //
//    MMWkkWMMMNc.lNNo';kWx..cXM0:xMNd:xNMMMMMM0:oXXNNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMNOKMWMWMxlKMNl.l0W0::xKWKlxMNx';KMWMMMMXcdMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMNkOMMMMMNXWWWKO0NMWWKXWWXKXMWx,xMMMMWMMXcdMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMWkl0WMMMWMKxockWKxokNKkdlxNN0l'dMMMMMWMk;kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMNOdkXMWWWdcx:dNocc;xl;xloOddo'oWMMMMXO:;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMWMNxlOWWMXkd:oNOodONKxxONKdxxcoNMMMMKxc;dXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMWdcKWMX0XxoNMWWWWMMMMMWWWWNNWMWMMMMWKkdkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMWOckMMXdc:kMWXXNWWNWMMXkdONWKkkOKWMMWMXodNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMXloNMMN0KWMk;ll;cldKWKo;'dWd.;dlkMMMMMOdKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMOcxWMMMMMMOcOk'dXoxM0l;.cNk:kNodWWMMWOkNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMWOcdNMMMMMNXNN0XWKKMNOxkKWN0XWXXWWMW0xKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMWWXxlxXWMMMMMMMMMMMMMMMMMMMWWWNXK0kkOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMWMWXxdddxxxxxxxddxxkkxdxkkxkkkxxkOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMN0kxxxkkkkkkkO0000KXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract PEPE is ERC721Creator {
    constructor() ERC721Creator("The PEPEstocracy", "PEPE") {}
}
