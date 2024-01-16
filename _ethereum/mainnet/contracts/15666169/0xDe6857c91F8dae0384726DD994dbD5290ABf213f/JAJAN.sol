
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jajan!!
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNXXXXXXXXXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXK0kxxddoolllcccccccclloodxkOKXNXKKKKKXWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNXKKXXNWN0kdoc:::::::::::::::c:::::::::;;;;clc:::::coONMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMXxlc::ccllc;;;:::::::::::::::::::::::::;;;::::::::::c:;;o0NWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWOc;:::c:::::::;;;;::::::::::::::::::::;::::::::::::::::::;;cd0NMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNx:::::::::::;;;;:::::::::::::::::::::::::::::::::::::::::::;;;:lkNMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNd:::::::::::;;:::;;;:::::::::::::::::;;;;;::;;:::::::::::::::;;:::lONMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMXd:::::::::::;;:::looooddddddxxxxxxxxxdddoolc::;;:::::::::::::::;;::::oKWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMXo:::::::::::;;:coxkO0000000000000000000000OOkdlc:;:::::::::::::::;;:::;c0WMMMMMMMMMMM    //
//    MMMMMMMMMMMMMNd:::::::::::;cdk00KKKKXXXXXXXXXXXXXXXXXXXKKK00OOOkdc:::::::::::::::;;::::cOWMMMMMMMMMM    //
//    MMMMMMMMMMMMNd:::::::::::cxKKXKK0OOkkkkxxxxxxxxxxxxxxxxxxxkkO00KKxc::::::::::::::;;::::;c0WMMMMMMMMM    //
//    MMMMMMMMMMMWk:::::::::::;lkxdoollcc:::::::::::::::::::::::::ccllooc;::::::::::::::;;::::;lKMMMMMMMMM    //
//    MMMMMMMMMMWOc::::::::::;;::;;:::::c::::::::::::::::::::::::::::::;;;;:::::::::::::;;:::::;oNMMMMMMMM    //
//    MMMMMMMMMM0l::::::::::;;::;;;:::::::::::::::::::::::::::::::::::::::;::::::::::::::;;::::;:kWMMMMMMM    //
//    MMMMMMMMMXo::::::::::;;:::lo::::::::::::::::::::::::::::::::::::::::;::::::::::::::;;:::::;lKMMMMMMM    //
//    MMMMMMMMWx::::::::::;;::::xOc:::::::::::::::::::::;clc:::::::::::::::::::::::::::::;;:::::;;kWMMMMMM    //
//    MMMMMMMM0c::::::::::;;:::c0Xo;:::::::::;;:::::::::;cOOc::::::::::::::;:::::::::::::;;::::::;lXMMMMMM    //
//    MMMMMMMXd::::::::::;;:::;oXNk::::::::::;;:::::::::;:kNKo:::::::::::::;;:::::::::::;;;;:;;;;;:OMMMMMM    //
//    MMMMMMMO:::::::::::;:::::xNWKl;::::::::;,;::::::::;:kNWXkl:::::::::::;;::::::::;;;;;;;;;;;;;;dNMMMMM    //
//    MMMMMMNd;:::::::::;;:::::kWWNk::::::::::,,;:::::::::dXXOkoc;;;;:;;;;;;;;:;;;;;;;;;;;;;;;;;;;,cKMMMMM    //
//    MMMMMM0c;:::::::::;;:::;:OWNWXd:::::::::;,;::::::::;cddx00d:;,;lkOxdo:;;;;;;;;;;;;;;;;;;;;;;,:0MMMMM    //
//    MMMMMNx;:::::::::;;;:::;cOWNWWKd:;:::::::;;;;;:coll:ckXWXo;::;;;xNWWNk:;;;;;;;;;;;;,,;;;;;;;,;kWMMMM    //
//    MMMMMKl;:::::::::;;:ccccoKWNWWWXOxddolcc:;cxkk0XXkoxKWMNxcdOOxl;oXWNWOc;;;;;;;;;;;;,,;;;,,,,,;xWMMMM    //
//    MMMMMO:;;;;;::::;;:kK0OO0KKKKKKXNNWWNNXK000XWWWWNXXNMMMKodKXX0d:lKWNWKc,;;;;;;;,,,,,,,,,,,,,,,dNMMMM    //
//    MMMMWx;;;;;;;;;;:cckKxdxxxxxxxxdddox0NWNWWWWWWWWWNNWMMMXol0K00xcdXWNWKl,;,,,,,,,,,,,,,,,,,,,,,oNMMMM    //
//    MMMMNo;;;;;;;;;;cxodXNNNWWWWNNNKxc:d0NWWWWWWWWWWWNNWWMMWOlokOkol0NNNW0c,,,,,,,,,,,,,,,,,,,,,,,lXMMMM    //
//    MMMMKl,;;;;;;;;;lOdoKWNWWWWWN0dlokKNWNNNNNNNNNNNNNNNWWMMWKkdddd0NNXXNO:,,,,,,,,,,,,,,,,,,,,,,,lXMMMM    //
//    MMMMKc,;;;;;;;;:x0xoOWNWWWNKxox0NWNNNNNNNNNNNNNNNNNNNNWWWWWNXXXXK000Kx;,,,,,,,,,,,,,,,,,,,,,,,lKMMMM    //
//    MMMM0:,;;;;;;;;lk0klkNWNXXK00XNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNK000000o,,,,,,,,,'',,,'''''''','cKMMMM    //
//    MMMM0:,,,,,,,,;dO0OodXNK00000KNNNNNNNNNNNNNNNNNNNXKKKXNNNNNNNNXKKKXX0l,,,,''''''',,'''''''''''cKMMMM    //
//    MMMM0:,,,,,,,,:x00OooKNXK0000KNNNNNNNNNNNNNNNNNOoloollxKNNNNNNNNNNNNO:''''''''''',,'',,'''''''cKMMMM    //
//    MMMM0:,,,,,,,,lk00kcoKNNNNNNNNNNNNNNNNNNNNNNNNkcokOOOd:xNNNNNNNNNNNXd,'''''''''',,,'',,'''''''cKMMMM    //
//    MMMMKc,,,,,,,;oO0xcl0NNNNNNNNNNNNNNNNNNNNNNNNKllOkxodo:xNNNNNNNNNNNKl''''''''''',,''',,'''''''cKMMMM    //
//    MMMMXl,,,,,,,;d0kcc0NNNNNNNNNNNNNNNNNNNNNNNNN0coOxl::oOXNNNNNNNNNNNk;''''''''''',,'',,,'''''''cKMMMM    //
//    MMMMNo,'',,,,;d0OocdKNNNNNNNNNNX00KNNNNNNNNNX0lcoood0XNNNNNNNNNNNNKo,'','''''''',''',,,'''''''cKMMMM    //
//    MMMMWx,'',,,':x00Oxlcd0XNNNNNNNX0xxxxxxxxxxxxxxk0XNNNNNNNNNNNNNNNNk:''',''''''',,'',co;'''';lx0WMMMM    //
//    MMMMMO:'':c,':x0000Oxlclx0XNNNNNNNNXK000000KXNNNNNNNNNNNNNNNNNNNNKl,'','''''''',;lx0XO;';lxKWMMMMMMM    //
//    MMMMMXl''lx:';x0O0000Ooccclx0XNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXd;'',,''''''';xKWMMMXxxKNMMMMMMMMMM    //
//    MMMMMWx,'l0o';d000Oxddx0XKkolldkKXNNNNNNNNNNNNNNNNNNNNNNNNNNNNKko;'',,''''',cd0WMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMM0c'cKO;,oOOxodONMMMMMWXOxolldk0KXNNNNNNNNNNNNNNNNNNXK0kol:,,,,,'',:ox0NMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMNd,:0Xo,lxod0WMMMMMMMMMMMWXOdolllodxk0KKKKK000OkkxxddxxOOl,::;:lx0XWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMM0c,kW0:;lONMMMMMMMMMMMMMMMMMWNX0OxdddxxxxxxxxkkO0KXWWMNx:xXXKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMWk;lXWOdKMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMMMMWKKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMWKkKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JAJAN is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
