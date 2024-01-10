
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GizmoTest
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMWWWWWWNNWWWMMMMMMMMMMMMMMMMMMMWNXXXXNNNNWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    WX000OOkxxdoooooodk0XNWMMMMMMMMMMWNK0OkddddxkOO0KKKKXXXXXNWMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    Xxc:::c:::;,,'.....':lk0XX0kk0KNX0kdoc,'.';odlokO00OOOkkxdxxdx0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    WXxccccccccc:;,'... ..,::::ccloxxxo:'.   .:xOkoodkOOOOOOxc;,,;:oxkO0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    NOo::lllllllllc:,'..';c:,',:lodxkxl;'. ..'oO0OddloxkO0KK0d:;;;ccc::cldkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    Kc. .;loooooollc;,',cdxdl:;:codxkkkxxol::cdkxooo:';oxO00Oo::odo;'.,;:cco0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    WXo'..,looooooll:,';lddc;;;;;::looooddddllll::::,.':c::cc;,coo,. .ll;:llo0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMW0c..;loollllc:,'';:;'.''',,;;;;:;;,;,,,,::::;,;:col:;;.';cl;...';,:dl:lkNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMXl..,loooll:,...''.....''',,,,,;;,,,,,;:;'.. ..'cdxdo;'';::;,,',:ddc;;cxKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMXl..,loool:'.............','',;;,,,,,,.        ;dxxxo:,,;:cloodddl:,;::ld0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMNx..;lolc:,''..     ....'''',;;,,,,'..        .cdddl:;;,,;:clllc:;,;:::coxOKK000000KKXNNWWWMMMMMMMMMMMMM    //
//    MMMMMMMWd..:llc;'...        ......',,,::,..','''.    ,oddl;;;;,,,,;;;;;;;;;::clodxxdolc::::;:loxk0KXNNWWMMMMMM    //
//    MMMMMMMMXl..;cc:,...          .........''..',,,;:'   .cooc;;;,;:;,;;;;;;::;;::codddol:;,,,.......',;:ldxO0KNWM    //
//    MMMMMMMMMk.  ......            .......';;cccc:;,,;;'.'colc::,',::;;::::;;:;;:cok000Oxoc::;,''''.........',;lOW    //
//    MMMMMMMMMK:.                    .....,:cldxxxxoc:;;:ccclc:;,'.,;;;;;;:::;;;;:lk0KK0OOxolcccllcccc::;;,''.'cOXW    //
//    MMMMMMMMMWKd,.                  ..''...',;lloxxxolc:;;,''''......',,;,;:;;,;:oOKKK0Okxdolccllooooolcc:;cx0NMMM    //
//    MMMMMMMMMMMWXx:..                ..'.......,:clodddxdo:,....  ....',,,,,;,,;cd0000OkxddooolllllloollllxKWMMMMM    //
//    MMMMMMMMMMMMMMNOo:'..           .....'''....''',;:cldxdoc,.....  ...'''''';ldxkkOkkkxdxxdollllllcoxO0XWMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWKkdl;..        .....'''',,'',,;:clldxxd:.  ..........'',ldxxxxxxxxxxxxxdlllllld0NMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWN0o;...       ......','',:ccccloodoc'    ...  ...,coddxxxddxxxkxxxxdoolloONMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWN0xo:,..       .......',,;;:cc::,.        ...',;cooddddddxxxxdddooodkXWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOo:,..         .......'....  ...  ....'......';:coollc:;;lk0KXWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kdc,.                         ..'.....  ....:c;,,;lxXWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxl:'..                    ......   .';dKNXXNWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xo:'.......        .......':lokKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kxdolc:;,'...',:odxOKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXK000KXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Gizmo is ERC721Creator {
    constructor() ERC721Creator("GizmoTest", "Gizmo") {}
}
