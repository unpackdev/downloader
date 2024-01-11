
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Dirt God
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                          //
//                                                                                                                                          //
//    ddddddddddxdddddddddddddddddddddddddddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOO    //
//    ddddddddxxxdddddddddddddddddddddddddddddddddddxxdxxxxxxxxxxxxxxxxxxxxxxxxkkxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOO    //
//    ddddddddxxddddddddddddddddddddddddddddddddddddxxdddddddxxxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOO    //
//    ddddddxxxdddddddddddddddddddddddddddddddddddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOk    //
//    dddddxxddddddddddddddddddddddddddddddddddddddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOk    //
//    ddddxxxdddddddddddddddddddddddddddddddddddddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOkk    //
//    dddxxxxdddddddddddddddddddddddddddddddddddddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOkkk    //
//    dddxkxxdddddddddddddddddddddddddddddddddddddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkkkxxxxkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    ddxxkxxddddddddddddddddddddddddddddddddddddddddddddddddddxxxxxdoollc:::::clodxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    ddxxkxdddddddddddddddddddddddddddddddddddddddddddddddxxxxxdoc:;,'''.......',;:coxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    ddxxxxdddxdddddddddddddddddodddddddddddddddddddxxxxxxxxxoc;,'...''''...........';coxxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkkkk    //
//    ddxxxxddddddddddddddddddddddoddddddddddddddddxxxxxxxxxl;'.........................';lxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkkk    //
//    dddxxxddddddddddoddddddddddddddddddddddddxxxxxxxdc;;:;'.............................':oxkkxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkkk    //
//    dddxxxxdddddddddooodddddddddddddddddddxxxxxxkkkkc'..'.............'''''.....''......'',lxkkkxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkkkk    //
//    ddddxxdddddddddddooddddddddddddddddxxxxxxkkkkxdoc'.''......','''''''''''''',;;'.''.'',',lkkkkkxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkkk    //
//    ddddxxddddddddddddoddddddddddddddxxxxxkkkkkkd;''''''''','.',,;coddo:,''',,,,,,'....''''';dkkkkkxxxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    dddddxxdddddddddddoddddddddddddxxxxxkkkkkOOx:'',,''',;;;'.',;cokOOOOxoc:;,'''.....''''''':xOkkkkkkxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    ddddddddddddddddddoddddddddddxxxxxkkkkOOOOOk:.',,'.',;;,..',cxOOO000O0Okdl;'..';:clll:,,'';okOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    ddddddddddddddddddddddddddddxxxxkkkkOOOOOOOOd,.','.',,'...,cx000O000000000Odoodxkkkkxo:'''.'oOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    dddddddddddddddddddddddddddxxxkkkkOOOOOOOOOxc,,,,'.,;'...;oO0000000000Oxdoooooxkkkkxol:'.'.;dOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    dddddddddddddddddddddddddxxxxkkkkOOOOOOOOOd,.',,''.;dl,';d0000OkxxddkOOxoo:,;;cxOkxlcc,.'''cxkOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    ddddddddddddddddddddddddxxxxkkkkOOOOOOOOOOc'''''...:xxlcoO00OOOOkxdlc:lk0OkddodkOkdlc;...''',;okOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    dddddddddddddddddddddddxxxxkkkOOOOOOOxoloxo,','...'oxxOkk000kxxdoooooc:lk0OOOOOkdlcc:,...','..'lOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    ddddddddddddddddddddddxxxkkkkOOOOOOkl,...','',;,..'okkOkkO00Odllc;,',:odkO00koc;,,;cl;...''....lOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    ddddddddoooodddddddddxxxkkkkOOOOOOOl'.........';,'.:xOOkkkO0000OxdollldkkO0x:,'.',,,,'........:xOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkk    //
//    ddddddddooodddddddddxxxxkkkOOOOOOOOo'....'''...'',..:odkkkO00000OOOkkO0000Oo;cl;;c;;;'.....';okOOOOOOOOOOOkkkkkkkkkkkkxkkkkkkkkkkk    //
//    xxxdddddooodddddddddxxxkkkkOOOOOOOOkl,''',;,'.',;,'...,dkxkO00000000000000Olcxxxoloo;....''',:dOOOOOOOOOOOkkkkkkkkkkxxxxxkkkkkkkkk    //
//    xxxddddddooddddddddxxxxkkkOOOOOOOOOOOxo:,,,,'.,,','....oOkxkO000KK00000O00kllxkkkxdc'....'....'lOOOOOOOOOOOkkkkkkkxxxxxxxxxkkkkkkk    //
//    xxxxdddddddddddddddxxxkkkkOOOOOOOOOOOOOd;,;;,;,'.......lOOkkkkOOOOOOOOOOO0klcdxxdl;,'........'.:kOOOOOOOOOOkkkkkkkkxxxxxxxxxxkkkkx    //
//    xxxxdddddddddddddddxxxkkkOOOOOOOOOOOOOOl..'',,'........:k0OkkkkkkkOO00kxxxo::odl:,.......''...'lOOOOOOOOOOOkkkkkkkkxxxxxxxxxxxkkkx    //
//    xxxddddddddddddddddxxxkkkOOOOOOOOOOOOOOx,......',......;x00OOOOOOOkxk0OOko:;:c:,..........'..,lOOOOOOOOOOOOOkkkkkkkxxxxxxxxxxxkkxx    //
//    xdxddddddddddddddddxxxkkkOOOOOOOOOOOOOOl'..............;dO00OOOkoccccoxxddl;;;,..........''.,oOOOOOOOOOOOOOOkkkkkkkxxxxxxxxxxxxxxx    //
//    ddxxdddddddddddddddxxxkkkOOOOOOOOOOOOOo.............':codok0xllxdcoxxxkdc;,,,'............':dOOOOOOOOOOOOOOOkkkkkkkxxxxxxxxxxxxxxx    //
//    ddxxdddddddddddddddxxxkkkOOOOOOOOOOOOOd'............ckxkxccxkxdk00ko:lxOOxoc,..'cc'.....'cdOOOOOOOOOOOOOOOOkkkkkkkxxxxxxxxxxxxxxxx    //
//    ddxxdddddddddddddddxxxkkkOOOOOOOOOOOOOOd:'..........;xOkkd::llloxkOkxxkkO0Oxc'.lkdolcclokOOOOOOOOOOOOOOOOOOkkkkkkkxxxxxxxxxxxxxxxx    //
//    ddxxdddddddddddddddxxxkkkkOOOOOOOOOOOOOOOo;'.........cOOkxo:;coxkkkoclkO0OOOOxloxo::lodkOOOOOOOOOOOOOOOOOOOkkkkkkxxxxxxxxxxxxxxxxx    //
//    dddddddddddddddddddxxxxkkkOOOOOOOOOOOOOOOkdc'.,:cccclokOxdoc;;;ldkOOxxkkO0OkkOOxdl'....',:cldkOOOOOOOOOOOOOkkkkkkxxxxxxxxxxxxxxxxx    //
//    dddddddddddddddddddxxxxkkkOOOOOOOOOOOkdl:,...'d000000OOkl:;:odddxxxoclkOOOOOOkkkOkd:.........';:ldkOOOOOOOkkkkkkxxxxxxxxxxxxxxxxxx    //
//    xxddddddddddddddddddxxxkkkkOOOOOOkdl:,.......'oOOOOOOOkxolldxdooxkOkooxxO0OkkkOkxxkd,............'dOOOOOOkkkkkkkxxxxxxxxxxxxxxxxxx    //
//    kkxddddddddddddddddddxxxkkkkOkxl:,...........'d00000OOOkl::ldllodxO0xdOOOOOOOxxkOkko,.............;kOOOOOkkkkkkxxxxxxxxxxxxxxxxxxx    //
//    kkkxxxxxxxdddddddddddxxxxkkko;...............'okkxkkkkkkdooddllodxk0dcokO0kxkOkxxxkd,..............lOOOOkkkkkkkxxxxxxxxxxxxxxxxxxx    //
//    kkkkxxxxxxxdddddddddddxxxxkkc...............'lk000000O0koc:lo:;''':ollxkkOOOkxxkOkxo,'''''.........:kOkkkkkkkkkxxxxxxxxxxxxxxxxxxx    //
//    kkxxxxxxxxxxxxdddddddddxxxkd,.............'..:dxddxkkkkkdoodo:,'..'cdxOOOOkkkOkxxxkd;',''''........'oOkkkkkkkkxxxxxxxxxxxxxxxxxxxx    //
//    kkkxxxxxxxxxdddddddddddxxxxo,........''''''..cdlcdO00OOkoc:ldl::;,;oxkOkOOOkxxkOkxxo,''''''',;;::ccldkkkkkkkkxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxdddddddddddddddxxl,'''.''..'''''''.:olloxkkkkkkxdxdcc:;,;oOOOkxxkOOkkkkkkxolooddxxxkkOOOOkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxddddddddddddddddddddooooooooooooooooloddodO00000OOkkxolodddddkOOOkxxxkkkkxddkOOOOOOOOOOOOkkkkkkkkxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    dddddxxddddddddddddddddddddddxxxxkkkkOOOOOOOOkxxdddodkOkkxxxkOOxxkkkkkOkxxkkxxxkkxlcxOOOOOOOOOOkkkkkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    ddddddddddddddddddddddddddddddxxxxxkkkkOOOOOOkxxxolldk000OO000kooddddkOOkxxkOOkxooclkOOOOOOOOkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    ddddddddddddddddddddddddddddddddxxxxxkkkkkOOOkxxxxxdodkO0kdxOOOOO0OkkkOOO0OkkkkdlcclkOOOOkkkkkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    ddddddddddddddddddddddddddddddddddxxxxxkkkkkkkddxxxolx0OkodOOOOOOOOOOOOOOOOOkdlooc:cxOkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    ddddddddddddddddddoddddddddddddddddddxxxxxkkkkxoddddddxo:cxOOOOOOOOOOOOOOOOOOkolllccdkkkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    ddddddddddddddddddddddodddddddddddddddddxxxxxxkdlodxkkOOxxOOOOOOOOOOOOOOOOOOOOkxdoollxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    ddddddddddddddddddddddddddoooddddddddddddddxxxxolcldkOO0OkkkkkkkkkkkkkkkkkkOOOOOkxxoloxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    ddddddddddddddddddddddddddoooooddddddddddddddddllodddxkOkxkkkkkkkkkkkkkkkkkkkkOOOkxddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    ddddddddddddddddddddddddddoooooddddddddddddddddddkOOOOOxxxxxxxxxxxxxxxxxxxxxxxxxxdddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    ddddddddddddddddddooddddddooooodddooodddddddddddkO000Oxdddddxxxxxxxxxxxxxxddddddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    dddddddddddoddddodddooddoooooooddddooooodddddddddkOOkxddddddddddddddddddddddddddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    dddddddddoooooddoddodddoodddooddddddooooooooodddooddddddddddddddddddddddddddddddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    ddddddddoooooooooooddddoodddooddddddoooooooooodoooddddddddddddddddddddddddddddddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    ddddddddddddoooooooddddddddooooooooooooooooooodddoooddddddddddddddddddddddddddddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    ddddddddooooooddodddddddddddooooooooooooooooooddoooddddddddddddddddddddddddddddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    ddddddddooooooddddodddddddddoodooooooooooooooodddddddddddddddddddddddddddddddddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    ddddddddddddooddddodddddddddoddoooooooooooooodddddddddddddddddddddddddddddddddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    dddddddddddddddddoddddddddddoooooooooooddoooodddddodddddddddddddddddddddddddddddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    kxxxdddddddddddddodddddddddddooodoooooodddoddoddddodddddddddddddddddddddddddddddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//                                                                                                                                          //
//                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract dirt is ERC721Creator {
    constructor() ERC721Creator("The Dirt God", "dirt") {}
}
