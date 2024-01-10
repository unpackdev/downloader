
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: tropoFarmer
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddddoooc::ccoxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdolllcc::::;;;;,;;,,:dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdolc::;;::::::::::::::;;;:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxdolcccldxxxxxdol::;::;:::cc:::;;;:;;:loo:;:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxo:;,;;,,,:dxolc;;;;;;:ldxxkkkkxxdoccdkOOkc,;cllccloxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxo:,:oxxxdc,,,'........,;;;;;::::coo:;::;;,'.....,;,;cdxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxo:;cxOOOOkxl.........,;;;;;;;;;c;.....,,,;;;;c;.,oxl;;oxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxo:;:dO000Okkkd;,,;;'..,;;;;;;;cdx:.ld,.,;;;;:lxc;okOd;,lxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxl;;:xKKKOkOKK0d:::;;'.';;;;;:lxkl',ll,..,;;:okd:okOOl,:oxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxl;,;x0K0kk0KKKx:;:;,'..',;:coxxdcclddc;:cllooc:lkkxl;:oxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxdc;;lOKKOO0K0Oxc;::;,'..;oooc;;coxO00xloc;:oocdOko:;coxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxdc;;lk00000OOd:;::::;;;cool;...,lxO0dlc;',cldxdc:coxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxdc:;:lodddol'.;:::::::;,,';cldk0OOOdx0Odc;;:::ldxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxollccccccc;,;::::::::;clx00OkO0KOxOK00Oo;;ldxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl;:::::::::lk00KK000KK0xk0KKKOlcdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:;;;::::::oOK0KKKKKKKKKkdOKKKKOddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo;;;;:::::oOKKKKKKKKKKKKOdx0KKKKOddxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxc,,;;::;:d0KKKKKKKKKKKK0KOxk0KKKKOddxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:.',,;;:o0KKKKKKKKKKKKKKK0kdk0KKK0xoxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdl;.''',ckKKKKKKKKKKKKKKKKK0xdOKKKKOodxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl'....;xKKKKKKKKKKKKKKKKKK0dd0K0Ododxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl;,'...ck00OOO00KKKKKKKK00KxlxOxdlldddddddxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl;;;,,'';lxxxxkkkkkkkkkkkkkdllool:coooooodxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl;::;;;,'...,,;:cloooodddddollllccodxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdc;:::::::;,.....,lllllllllooodddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:;::::::::::;;,':dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdc;::::::::::::::;:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdc;::::::::::::::::;:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdl:;::::::::::::::::::;:ldxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxdoc:,',,;;;;;;::::::::::::;;,;:clddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxolcc::;,,,;;;;::::::::::::::::::::;;;;::cldxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxdl:;;;;:::::::::::::::::;::::::::::::;:::::;;;cdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxl;;;:::::::::::::::::::;;,,;:::::::::;;,;:::::;;:dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxdc;;::::::::::::::::::::ccc:,,,;:::::::;,,:::::::;;cxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxc,;:::::::::::::::::::lxkkOx;''',;;;;::;,cxxo:::::;;oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxo;,:::::::::::::::::cdk0KKKK0xlc:;:;',;;,:x0K0d:;;:;;lxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxl;;::::::::::;;:;;cx0KKKKKKKK0000OOkoc::lk0KK00x;';;,cxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    kxxxxxxxxxxxxxxd:',;;;;:::::;,,;:oOKKKKKKKKKKKKKKKKKK0Okk0KKKKK0d;;;,:dxxxxxxxxxxxxxxxxxxxxxxxxxxxxk    //
//    KOkxxxxxxxxxxxxd:.',,,::::::;'',d0KKKKKKKKKKKKKKKKKKK0KOdkKKKK0KOl;;,:dxxxxxxxxxxxxxxxxxxxxxxxxxxxOK    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TROPO is ERC721Creator {
    constructor() ERC721Creator("tropoFarmer", "TROPO") {}
}
