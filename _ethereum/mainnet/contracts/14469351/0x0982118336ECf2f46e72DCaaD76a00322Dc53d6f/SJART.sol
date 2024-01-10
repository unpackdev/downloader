
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Susan Jean Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO00OOOxo:,;;;;;,;;;::;,'......',;;;;;;cdO0OO00OO0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0OOOxl;;:;,;;:::;;,,',,;:;,'.....';;;;;;:dk0OO000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOd:;;;,:clodddddolc:;;,,,;;;;,....,;;;;,:dO0O0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0d:,,;:ldddddddddddddddolc:;,;;;;'...,;;;;;lk0OOOOOO00OOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOO0OO0OO0x:,;codddddddddddddddddddddol;,,;;;,'..';;;;cxOOOOO000OOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOO00OOO0Oc':oddddddddddddddddddddddddddl,,;;;;,...,;;;:oO0OO0OOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0k::dddddddddddddddddddddddddddddo:';;;;;,..';;;;lO0OOOO0OOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOO0Oocoddddddddddddddddddddddddddddddd:',;;;;;'..';;;lk0O000OOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOO0OO0xclddddddddddddddddddddddddddddddddd:',;;;;;'...;;;cxO0OOO0OOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOO0O00OOocddddddddddddddddddddoooooooodddddddc',;;;;;,...;;;;oO0OO0OOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOO00OO0Olcddddddddddddddolcc:;,,,,,,,,;;ldddddc',;;;;;,..';;;,lO0O0OOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOO0OOOOOOOO0OO0k:,::cloddddddddo:,,,,;ccllloolc:;;ldddd:';;;;;;,..';;;,lO0OOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOO0OOOOOO0OOOO0k;,:;,,;coddddddoc;:clooooooooloddc:ldddd:';:;;;:,..,;;;,oOOO0OOOOO0OOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOO0OO0O0kclddoc:;codddddddoddoloododdoolloddoddddd:,;;;;;;...;::;;oO0OOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOO0OOOOOOO0OO0O0Ollddoolooloddddddddollll:::cccl::ldddddddo;,;;;;;,..,;;:,;d0O0OO0OOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOO00OO0Oocoolcccccloddddddocldkl,,.,;,;,,cddddddddc,;:;;;;..';;;:,ck0OOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOO0OO00Ooccll;.';;codddddddlccc:;;,,;:clddddddddddl,,;;;;;'..';;;;;d0O00OOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOO0OO0Ol;::l:,;cclddddddddddddddoddddddddddddddddo;::;;;;;...,:;;,ck0O0OO0OOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOO00OO0d,:ddddddlcodddddddddddddddddddddddddddddddo;cd:,;;;'...;;:;,o0O00OOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOO0OO0k:,odddddocoddddddddddddddddddddddddddddddddo:cddc,;;,...;;;;,:k0O0OOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOO0O0d':ddddddclddddddddddddoloddddddddddddddddddo:cdll:,;;...,;;;,;x0OO00OOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOO0Oc'cdddddocoddddddodddddo:lddddddddddddddddddo:llcl:';;'..,;;;;,oOOO0OOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOO0OO0x;'cddddddlclooolllllloddlcccloddddddddddddddl:ooclc;,;,..';;;;,cO0OO0OOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOO0Ol,,:oddddoollllooddddddddddolccllodddddddddddc:odlll,,:'..';;;;;:k0OO0OOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOO0x:;;,cdddocldddooodolllllllllllloooddddddddddl::lo:'..,:'..';;;;;;x0OOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOO0Oo;;:;,cdddlcc;clcllllc:::;'.';';oddddddddddddccl,''...;:'..';;;:;;o0O0OOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOO0kc;:;;;,:ddoo:'';:cclllc::::c:;;lddddddddddddl:ol,'.',';;'..';;;;;,lO0OOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOO0d;;;;;;;,:odddl;;cllooolcccc:cloddddddddddddl:od:,;;;'';;'..';;;;;,lO00OOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOO0OO00OOOl,;;;;;;;,;odddoc:ccccccc:codddddddddddddddlcldo;,;;;',:;'...,;;;;,cO0OOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOO0OOOO00O0Oc,;;;;;;;;,:oddddddooooddddddddddddddddddoccoddc,;;;,';;;,...,;;;;,:k0OOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOO0OOOOd:;;;;;;;;;;,;odddddddddddddddddddddddddoccodddo;,;;;',;;;;'..,;;;:':k0OOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOO000O00O0Od:;;;;;;;;;;;;;;ldddddddddddddddddddddolccldddddl,;;;,';:;;;'.';;;;:,:k0OOOOOOOOOOOOOOO    //
//    OOOOOOOO0000O0000OOOOOo;;:;;;;;;;;;;;;;;ldddddddddddddddddlccclodddddddc,;;;',;;;;;'.';;;;;,cO0OOOOOOOOOOOOOOO    //
//    OOOOOOOOO00OOO00OOO0Oo;;;;;;;;;;;;;;;;;;;lddddddddddolccclclodddddddddd:,;;,';;;;:;'..,;;;;,lO0OOOOOOOOOOOOOOO    //
//    OOOOOOOOOO00000OOOO0d:;;;;;;;;;;;;;;;;;;;;:ccloollccccllodddddddddddddd;,;;',;;;;;;'..';;;;,lO0OOOOOOOOOOOOOOO    //
//    O0OOOO00Okxddooooddo:;;;;;;;;;;;;;;;;;;;;;;;,;;;;;:lddddddddddddddddddo;';,';;;;;;;'..';;;;,lOOOOOOOOOOOOOOOOO    //
//    OOO0Okdoollloddddddc,;;;;;;;;;;;;;;;;;;;;;;;;;;;:;;;coddddddddddddddddo;';',;;;;;:;,..';;;;'cO0O0OOOOOOOOOOOOO    //
//    OOkollloddxdddddddxl,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;coddddddddddddddo;''';;;;;;;;,..';;;:';k0O0OOOOOOOOOOOOO    //
//    xlclddddddddddddddxo;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,cdddddddddddddc..';:;;;;;;;,..';;;:;,o0OOOOOOOOOOOOOOO    //
//    coddddddddddddddddxd:,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:,';odddddddddddo;'.';;;;;;;;;;'..;;;;:,;x0O0OO00OO0OOOOO    //
//    dddddddddddddddddddd:,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:;',ldddddddddddc:c,,:;;;;;;;;:;..,;;;:;':k0OOOOOOO0OOOOO    //
//    ddddddddddddddddddxo;,:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:,',lddddddddddl;lc,;;;;;;;;;;;;...;;;:;;',okOO0OOOOOOOOO    //
//    ddddddddddddddddddxl,;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,.;odddddddddo:co;,;;;;;;;;;;;;,..,;;;;:,.;lllodO0OOOOOO    //
//    dddddddddddddddddddc,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,.:ddddddddddc:oc,;;;;;;;;;;;;;;'.';;;;:;':xddlccdO0OOO0    //
//    dddddddddddddddddxo;,:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:,,:ldddddddddo:ld:,;;;;;;;;;;;;;;;..,;;;;;,;oxdddoccxOOO0    //
//    dddddddddddddddddxl,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,cdddddddddddc:do,,:;;;;;;;;;;;;;;'.';;;;:,,lxdddddl:d0OO    //
//    dddddddddddddddddd:,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;.,oddddddddddl:ldl,,:;;;;;;;;;;;;;:,..,;;;:,,oxdddddxl:x0O    //
//    ddddddddddddddddxo;,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,:dddddddddoccddc';;;;;;;;;;;;;;;;;'.';;;;,;dxddddddxlcxO    //
//    dddddddddddddddddc,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;',oo;,cdddddddc:odd:';;;;;;;;;;;;;;;;;,..,;;;'cxdddddddddlck    //
//    dddddddddddddddxd;,:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,':ddl::cdddddo:cddd:';;;;;;;;;;;;;;;;;;,..;:,,oxddddddddxd:o    //
//    dddddddddddddddxl,;:;;;;;;;;;;;;;;;;;;;;;;;;;;;:,':lodddl:cddddc:oddd:';;;;;;;;;;;;;;;;;;:,.,:':dddddddddddxlc    //
//    dddddddddddddddd:,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:,,ollddddl;cddl;cdddd:';:;;;;;;;;;;;;;;;;;;,;;'cxddddddddddxdc    //
//    ddddddddddddddxo;,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;';doclddddl;co;;oddddc',:;;;;;;;;;;;;;;;;;;;:;'cxddddddddddddd    //
//    dddddddddddddddc,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:,,oxoclddddl;''ldddddo,':;;;;;;;;;;;;;;;;;;;:;'cxddddddddddddd    //
//    dddddddddddddxo;,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;':dxo:;ldddc.'ldddddd:';;;;;;;;;;;;;;;;;;;;:;':xddddddddddddd    //
//    ddddddddddddddc,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:,,lxxo::ldl:;;codddddo,':;;;;;;;;;;;;;;;;;;;:,,oxdddddddddddd    //
//    ddddddddddddxo;,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;';oxdxl:lc'',:oddddddc',:;;;;;;;;;;;;;;;;;;;;':ddddddddddddd    //
//    ddddddddddddd:,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;':ddxdc:c:,,ldddddddo;';;;:;;;;;;;;;;;;;;;;;;':dddddddddddd    //
//    dddddddddddxl,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:,'cddddc;loddddddddddl,';;;:;;;;;;;;;;;;;;;;;;':dxddddddddd    //
//    ddddddddddxo;,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;',oxxddc;coddddddddddl'';;;;;;;;;;;;;;;;;;;;;;,;lddddddddd    //
//    dddddddddddc,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;';odxddoc:ccloddddddl;',;;;;;;;;;;;;;;;;;;;;;;,,cdddddddd    //
//    dddddddddxo,,:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:,',lxdddddoccccc:clc:ll,';;;;;;;;;;;;;;;;;;;;;;;,;odddddd    //
//    dddddddddxc';:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;'.;dddddddxxxdoolc:lddo;',;;;;;;;;;;;;;;;;;;;;;;,,cddddd    //
//    ddddddddxd;,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:'.,oxddddddddddddxxdddddc,',;;;;;;;;;;;;;;;;;;;;;;';oddd    //
//    ddddddddxo,,:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:,.'lxdddddddddddddddddxdddc;,',;;;;;;;;;;;;;;;;;;;;,,ldd    //
//    ddddddddxo,,:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:,''cxdddddddddddddddxdddddxdo:,,,;;;;;;;;;;;;;;;;;;;,'cd    //
//    ddddddddxd;';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,':xdddddddddddddddddddxddddddl:;,,;;;;;;;;;;;;;;;;:,'c    //
//    ddddddddddc';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,':xdddddddddddddddddddddddddddxdlc:;,;;;;;;;;;;;;;;;,'    //
//    dddddddddxl,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:;''cxddddddddddddddddddddddddddddddddo;';;;;;;;;;;;;;;:,    //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SJART is ERC721Creator {
    constructor() ERC721Creator("Susan Jean Art", "SJART") {}
}
