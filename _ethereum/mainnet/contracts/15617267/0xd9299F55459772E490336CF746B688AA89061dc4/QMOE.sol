
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Quantum Encabulator
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ;:clloooooddxxdoocclllodolodddoll::ldxxxxxddoc:::::;;;;;;:cc::cc::::::ccc:;;::cc::clloddddxxxdollooo    //
//    ::::cllloddddxxdolclllodolodxxdllc:cdxxxxxxdolc:::::;;;;;:cccccc::::::ccc:;;;:::cclloodddxxxxdollood    //
//    :::cccloddddxxxddlclollddoodxxdoll:cdxxxxxxddolcccc:;;;;;:cccccc::::::ccc:::;;::clllodddxxxxxdollood    //
//    ;::cllloddddxxxxdollolcddoodxxxollccoddddxddollc::::;;;;;::cc::::::::::::::::;;:cllodddddxxxxdoollox    //
//    ;;;:clooddddxkkxddooolcoxddxoc;;;;,,;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,:c::;;:cooodxxxxxxdoodddood    //
//    ::;;:looodddxxxxddooolcodooc;''''''''''''''''''''''''''''''''''''''''''',colllccloddxxxxxdollloddooo    //
//    ;;::coooodxxxxdoodddoolldo;..............................................,::loolccllloooddoooddddddd    //
//    cccclodddxddddollodxddoodd;.                                            .;llloolllllodxxxxxxxkkxdodx    //
//    looolcccllooodddddxkxoodxx:. .............................''''''''''''. .:ooooooooddddddoddxdddddodx    //
//    clollllllodxxddxxxkkxoodxx:...,'.................'''''''''''''''''''''. .;llllollcccllooooddooodolod    //
//    ooooodooddddooodxxxddooodd;...'.                                        .:lllloollllloodddooolloolod    //
//    lllllllccclooooooooloooooo;...'.                                        .:ooloodddddddddolccloddoc:c    //
//    llllooolcclodddolcclodolcc;. .'.                                        .cdoolodxxxdoodddolloddoc:ld    //
//    oollodddodxddoollcloddoc:l:. .'.         .....................          .coolodddddooodkkxddolll::lo    //
//    dddoloxxxxxdooxxddddolc::c;. .,.     ..............................     .;::cloooolcccldxddddlccc:;;    //
//    ddolloddddolloxxxddoo:;cl:,. .,.     ..............................     .;;::::;;;;;;:clooool;;:;;;:    //
//    llcclooool:::clddoool;,;:,'. .,.        ..........................      .,,,'',''',,,;;:::::;,;:;',;    //
//    ;;;;:cc:;;;;;;cccclc:,;:;;'. .,.    ..............................      .,,,,,,,''',,;,,,;::ccccc:::    //
//    ;::;;,,,,'',;;::::::::ccll:. .,.   ................................     .cllccc:;;;;,,,,,;::looooooo    //
//    ;:;,,'',;'';loolloooooodddc. .,.   ................................     .:cccccc:::::;;,,,;:cloooood    //
//    clc::;;::;;loooodddoodddddc. .,.   ................................     ':c:::cc::::::;;;;;;::cllloo    //
//    llllllllc;:looddxddddxxdddl. .,.                ...................     ':::::ccc::::::;:::::::ccccl    //
//    oollllllc,,codxxdddxxxxxddl. .,.                                        .;::cccc::::::;;:::c::::cclc    //
//    ddllllllc;';odxxxddxxxxxxdl' .,'   ........                            .';::ccc:;;;;;;;::cc::::cclll    //
//    ddollllll:',ldxxxxxxxxxxxxo' .;'.  .................                   .'::cccc:;;;;;;;;::::::ccllll    //
//    dxdllllllc,':oxxxxxxxxxxxxo' .;'.  ........................            .':cccc::;;,;;;;;;:::ccclllll    //
//    dddollllll:,;oxxxxxxxxxxkxd, .;'.                    ......            .':cccc:::;;;;;;;::;;:clllllo    //
//    xdddolllllc,,cdxxxxxxxxxkkd, .;'.                                      .,:cccc:::::;;;;;::;;:clllllo    //
//    kxddollllll:;:oxxxxxxxxxkkx, .;,.                                      .,:ccccc:::c:::::::;;:clllllo    //
//    Oxxddolllllc;:oxxxxxxxxxkkx; .,,...................................... .,cllllcc:cc::::::::::clooooo    //
//    Okdddolllllc::ldkxxxkxxxxxd;  ........................................ .,:cc::::::::;;;;;;;:cllllllo    //
//    kkxxddolllll::oxxxxkkxxxxxd;.                                          .:llllccccc:;;;;;;::lodddoolc    //
//    kOkxdddolccc:cclodxxkkxxxl;.............................................;odddddddoolllccc::ccldxkkkx    //
//    xkxxxxdl:;;;clooddxxxxxxc'...'........................'.................':ooolooooooodddoolllloddxxx    //
//    xdllddolc;;:cccllddolll:'.............................'..................:cccc:::ccclloooolccccccccc    //
//    xlllllc:cccccloodoolll;..................................................:cllcc::;;::llllc::::::cccc    //
//    occcc:;:codxxxxxxxxxxl'.................................................'cllllllllclllllllccc:::cclo    //
//    dl:clooooodxxkOOkkkkkl,.................................................'ldddddddddddddddddoooloodxx    //
//    xxdxxkkkxooodxxxxxxxdooc.                                             ..,::cccclllllllloooddddddxxkx    //
//    OOkkkkkxxdlloooooodxxxxl'                                             .':;::cccllllllllllllllllooood    //
//    kkxdddddolloddxdollllllc'.                                            .,ccccclllllllllccccc::ccccllo    //
//    xdoodoloollodxxxxdddoolc,.                                            .;oooooooooooooolllcc::::ccccl    //
//    lldolodxxxoodxxdddooooll;.                                            .;lclloolooollccloollcc::::::c    //
//    ldxxodxkkkdoooodddolc:::;.                                            .:c:cllooooolccloddddddoollllo    //
//    ddkOkdoooooolloddddoc;;;;..                                           .:oloodddddddoolooodooolooodxk    //
//    doxkOxollcccloooooool:;:c,..   ..................... ..               .cxddddddddddoolloddddxxxxxddo    //
//    loxxxdollol:cooolllc:;;:c;......................................      .lxooooodddoolcclodxxxxxxddoll    //
//    coxkxdoloolc:::ccllc::cll:.......................  .......   ...      .ldloodddddollccodxxxxdddddoll    //
//    oxxkkkdodddo:;:ccccc:;codl.................................  ...      .lollodddollllloddddddddddolcl    //
//    xkxdxkxodddl;;coc:;;:::ldo,................................. ...      .:c;;:cc::;:clllddddddddolcclo    //
//    xxxdooooolc:;;lolc;;looloo;.........................    ...  ...      .::;;;;,;;;;;;:lddddddoc:;:cll    //
//    cccc::cccl:;;;:lool;:loool;.......................................... .:;,,;;;:;;;;:lllccccc:;;;::::    //
//    :;,:clllccc;;;::ccc:;;cool;.......................................... .;;,;:::;;;::c:;;;;;;;;;;;;;;:    //
//    c:;;:cccccc:;;;;;;;:c::col:............................................;,,;;;;;:;;;,,,,,,,,,,;,,,,:c    //
//    :;;::::c:;cc;;,;;:;,::::cc;............................................'...',,,,,,,,,,,,,,'',,,,,;::    //
//    ,'',:;,::;;c:;;,;:;,,,,,,,,.............................................   .................',,,,,,,    //
//    ;'',;,,;:;,;;,,,;;;;;,,,,,,'...........................................;;,,;;;;:;;;,,,','....',,,,,,    //
//    ;'',;;,,;;;;;;;::::ccccc::;,'.........................................'cooollllloolcc::;;,,,,',;;;,,    //
//    ;,,;:;;;:cllllollcclllcc:,,,;,',;:;,,,''';:cc::;;::::::;;;;;;,..   ...;clllllllcccllllc:;;;;;,,,,;,,    //
//    :clolcccllooooolllllllc:,,,;,,,;;;,,,',;:lllc:::cllllllccclloo:.   .':ccllllcccccc::clllc:;;;;;,,,,,    //
//    lodolllloooodolcclllllc;;;;;,,,,,,,,;;:clcc:;:clllccccccccllool'   .;llllllcllc::clc:::cllc:;:::;,,'    //
//    oxdoloooddddolccclllll:;;;;;;;,'',;:cllcc:;:cllcc::ccccclloooll;. .'clllllllcccc::clll:;;:ccc:;:::;,    //
//    xxdoooodddddoc::cllollc::;;:;;,'',;clcc:,,;clc::::::::clooollcc:. .,cllllllllc:;;;::cll:;,;clc:;:cc:    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract QMOE is ERC721Creator {
    constructor() ERC721Creator("Quantum Encabulator", "QMOE") {}
}
