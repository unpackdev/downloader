
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RAERAEVERSE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    ooooodxxkOOO000KKKKKKKKXXXXXXXXXXXXXXXXXXXXK0KXXXXXXXXXXXKKKKKKK00000OOOOkkkkxxx    //
//    ooooodxkkOO000KKKKKKKKXXXXXXXXXXXXXXXXXK0xl::coxxOKXXXXXXXKKKKKK000000OOOOkkkkxx    //
//    ooooodxkkO000KKKKKKKXXXXXXXXXXXXXXXXKOkdc:,,'..';oOKXXXXXXXKKKKKK00000OOOOkkkkxx    //
//    ooooodxkkO000KKKKKKXXXXXXXXXXXXXXXKOo;;,,,'....,:ok0KXXXXXXKKKKKK00000OOOOkkkkxx    //
//    ooooodxkkO000KKKKKKXXXXXXXXXXXXKKOo;''.........,ldooodk0KXXKKKKKKK0000OOOOkkkkxx    //
//    ooooodxkkO000KKKKXXXXXXXXXK0Okdlc;'.............,oxxdl::d0XKKKKKK00000OOOOkkkkxx    //
//    ooooodxkkOO00KKXXXXXXXKOkdlc:;,,;;'.;:;'.........'cxxc,,;dKKKKKKK00000OOOOOkkkkx    //
//    ooooodxxkOO00KKXXXK0Odl:;;,,,:lxOx;'loc;,'........;do:;,,l0XKKKKK00000OOOOOkkkkx    //
//    ooooodxxkOO00KXXXKxl:;,,,';lkKNNXOc',::,,'.......'oko:;,,;xKKKKKK000000OOOOkkkkx    //
//    ooooodxkkO00KKXXXKx:;,,',l0NNNNNW0l,,;;'',,'.....c00o:;,,,l0XKKKKK00000OOOOkkkkx    //
//    ooooodxkkO00KXXNNNKd:;,,,cx0NWNNWKo:;:;,',,,...';lOKdc:,'':kXKKKKK00000OOOOkkkkx    //
//    ooooodxkkO00KXXNNNNXx:;;,,,;lkXNNKdclo:,,,,,'..,lxkOdc:,'',xXXKKKK00000OOOOkkkkx    //
//    ooooodxkkO00KKXXXXNNNOl;;;,,,,:ok0xoxOxc;,,'...':O0xol:,'.'oKXXKKKK00000OOOkkkkx    //
//    ooooddxxkOO0KKKXXXXNNNKd:;;,,,,'';clkXN0xl,,''''':odoc:,''.:OXXXKKKK0000OOOOkkkx    //
//    oooooddxxkO00KKXXXXXXXNX0d:;,,,,,,,,;ldolc;;;'''''';:::;''.;kXXKKKKK0000OOOOkkkx    //
//    ooooodddxxkO0KKXXXXXXXXXNX0dc;,;;:,'',;::::;;,'''',,,::;,'':OXXXKKKKK000OOOOOkkx    //
//    ooooodddxxxkO0KKXXXNNXXXXXNXKkl::,'.';::cc::;,'..',,,,;;,',dXXXXKKKK00000OOOOkkx    //
//    oooooodddxxkkO0KKXXXXXXXXXXXNNXOo;,'';;clll:,,'...,,,,,,,:kXXXXXKKKK00000OOOOkkx    //
//    ooooooddddxxkkO0KKKXXXXXXXXXXXX0o:;'.',:llc;;;;,..,,,,,,:OXXXXXXKKKKK0000OOOOkkx    //
//    oooooooddddxxkkO00KKKXXXXXXXXKdcc;,,...;clc:;;;;'..,,,,:kXXXXXXKKKKKK0000OOOkkkx    //
//    ooooooodddddxxxkOO00KKKXXXXXX0c'''.....';:;'..''....',:kXXXKKKXKKKKK00000OOOkkkx    //
//    ooooooooddddddxxxkOO00KKKXXXXXx,.........''..........'dKXKXKKKKKKKKK00000OOOkkkx    //
//    lllloooooddddddxxxkkO000KKKXXXKd'....................lKKKKKKKKKKKKKK0000OOOOkkkx    //
//    lllllooooodddddxxxxxkkO00KKKKKXOl::;,','''..........:0XKK000KKK00000000OOOOkkkkx    //
//    llllllloooodddddxxxxxxkkO00KKKXOoc::;;::;;;,,'''''.:ONXKK0kxOO00000000OOOOkkkkxx    //
//    cclllloooodddddddxxxxxxkkO00KKKOl::;;;;;,,,,,,,,,,,oXNXXKKOxxxkOOOOOOOOOOkkkkxxx    //
//    llooooddddxxxxxkkkkkkO00KKXXXXXkc;::;;;,,,,,,,,,,',dXXXXKKKK0OxxxkkOOOOkkkkkxxxd    //
//    lloodoooddddxxxk00OkkO0KKKKXXXKo;;::;;;,,,,,,,,,,';xXNXXXXKKKK0Okxxxxkkkkkxxxxdd    //
//    ooooooodddddxxxkO0OkddxOO000KXk:;;;;;,,,,,,,,,,,,'.,lOXXKKK00OOOkkxddddxxxxdddoo    //
//    loooooodddddxxxkOOkkoclodkOOko:,,;;;,,,,,,,,,,,,'.''.;lxkkkxxxdddddddddddkkkkdol    //
//    oolloooooodddxxxkxddlc:clodkl'''';;;,,,,,,,,,,,'.''.''..:odddddoollooddxxkOOOOkd    //
//    dollllllloddddddooollclllllc;'...',,,,,,,,,,,'..'..''....:oooodddxkOO000000OOOkk    //
//    ooollllclloooollccllloddoc:;,'....','',,,,,,'....'''.....';lxkOO00000000OOOOOOkk    //
//    ooolllccccccccc:ccloolc:;,,'''......''''''''....'.......'',;ok00000000OOOOOOkkxx    //
//    lloollccc::cccloddlc:;,,,''''''........'''............''',,,;cxOOOOOOOOOkkkkkxxx    //
//    ccclloolcccloodol:;,,,'''''''''''...................,,;;,,,,,,;cdxxxxxxxxxxxddxx    //
//    llccllllclooolc:;,,''''''''''''''................',,;;;::;;,,,,,;:looooddddooddo    //
//    :::cccccccllc;;,,'''''''''''''''................',,,;;;;:::;,,,,,,,:looooloooool    //
//    ::::::cccc:;,'''''''''''''''.....'',,,;,,,,;;;,,,,,,;;;;;:::;,,,,,,,,:clllllllll    //
//    cc:::::::;,''''''''''''''....',;:ccllloooooddddooc:;;;;;;;;::;;,,''''',;clllllll    //
//    :::;;;:;;'.''''''.'''...',;:clooddxxxkkkkkkkkkxxxxdl:,,,,,;;;;;,,''''''',:ccccll    //
//    ;;:::ccllccc;;:::::ccccldxxxkkkkOOOOOOOOOOOOOOkkkkxxol:,,,;;;;;;,,''''''';:ccccl    //
//    ccccllooddxxddxkOOOO00OOOOOOOOOOOOOOO00O000OOOOOOkkkxxdl:;,;;,,,,,,''''''';:::cc    //
//    llloodddxxkkxkkkOO00000000000OO0000000000000O00OOOOOkkxxdl:;,,,,,,,''''..'';;::c    //
//    ooodddxxxxkkkkkkkOO000000000000000000000000000000OOOOOOOkkxdlc:;;,,,'......;cloo    //
//    oodddxxxxxkkkkkkOOOOO00K00000OO0RAERAEVERSE.G00000000OOOOOOOkkddoooolcccccldxxxx    //
//    ooddddxxxxkkkkkkkkkO00O0KKKKK00O000000000000000000000OOOOOOkkxxxdxxkkkxkkxxxxxxd    //
//    ooddddxxxxkkkkkkkOOOO0OO00KKK000000000000000000000OOOOOOOOkxkkxdxkkkxkkxxxxxxxxx    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract RRVG is ERC721Creator {
    constructor() ERC721Creator("RAERAEVERSE", "RRVG") {}
}
