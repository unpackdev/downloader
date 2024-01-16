
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eaves
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    loxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    c:coxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    lccloddxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    llllollloxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOkkOOkkkkkOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    llllllllllodxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOkkOOOOOOOOOOOkkkkkkkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    lllllllllllcloxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOOOkkOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    lllllllllllllllodxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOOOkkkOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkk    //
//    lllllllllllllllclloxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOkkkOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkk    //
//    llllllllllllllllllccldxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOkkkOOOOOOkkkkkkOOOOOkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    llllllllllllllllllllccloxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    lllllllllllllllllllllllllodxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    lllllllllllllllllllllllllllldxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkxd    //
//    llllllllllllllllllllllloolllllodxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOkkkkkkkkkkkkOOOOOOkkkkkkkOOOkkkkkkkkkkkkkkxdoo    //
//    clllllllllllllllllllllloolloolllldxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkOOOOkkkkkkkkOOOOkkkkkkkkkkkxdollo    //
//    ccclllllllllllllllllllloollloolllllodxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOkkkkkkOkkxolloooo    //
//    llccccllllllllllllllllloollloolllolllldxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkkkkkOOOOkkkkkOkxooloooooo    //
//    llllcccclllllllllllllllollloollllolllllllllldkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOkkkkkkkkkkOOOOOOOOOkdolloooooooo    //
//    llllllcccccllllllllllllolllooolllllllllllllccdkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOkkkkkOOOOOOOOOOOOOkdololooooooooo    //
//    lllllllllccccclllllllllolllooolloolllllllolllldxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOkkkkkkkkkkOkOOOOOOOOOkdolooooooooooodd    //
//    llllllllllllcccllllllllollloooloooooollllooolllodxkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOkkOOOOOOOOOOOOkxdolooooooooooodddd    //
//    lllllllllllllllccccllllllllooooooolooolllooolloollodkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOkxollooooooooooodddddd    //
//    lllllllllllllllllccccllllllolllooooolooolooolloooollodkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOkdollooooooooooooddddddd    //
//    lllllllllllllllllllccclllllllllllooooolllooolooooololoxOkkkkkkkkkOkkkkkOOOOOOOOOOOOOOOOOOOOOOOkdollooooooooooooooddddddd    //
//    lllllllllllllllllllllllcclllllllllloooollooooooooooolokOkkkkOOkkOOOOOOOOOOOOOOOOOOOOOOOOOOOkxdllooooooollooooooodddddddd    //
//    ccllllllllllllllllllllllccclllllllllooooooooooooooooodkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxollllooooooloooddddoddddddddd    //
//    ccccclllllllllllllllllllllllccclllllllllooooooooooooodkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxollllooooolloooodddoooodddddddd    //
//    lllcccclllllllllllllllllllllllccclllllllloooooooooooodkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxoooooooooooooooooooodoodddddddddd    //
//    llllllccccllllllllllllllllllllllccccllllllooloooooooodkOOOOOOOOOOOOOOOOOOOOOOOOOOOkkdooooooooooooooooooooooddddddddddddd    //
//    llllllllccccclllllllllllllllllllllccccllllooloooooooodkOOOOOOOOOOOOOOOOOOOOOOOOOkxdooooooooooooooooooooooodddddddddddddd    //
//    lllllllllllccclllllllllllllllllllllllcccclllloooooooodkOOOOOOOOOOOOOOOOOOOOOOOkxdooooooooolloooooooooooodddddddddddddddd    //
//    lllllllllllllccccllllllllllllllllllllllcccclllolllloookOOOOOOOOOOOOOOOOOOOOOkxdolooooooolloooooooooooodddddddddddddddddd    //
//    llllllllllllllllccccllllllllllllllllllllllcccclllllllokOOOOOOOOOOOOOOOOOOOkxdooooooooolooooooooooooooodddddddddddddddddd    //
//    llllllllllllllllllccccllllllllllllllllllllllccccllllloxOOOOOOOOOOOOOOOOOkxdooooooooooooooooooooooooddooodddodddddddddddd    //
//    lllllllllllllllllllllccccllllllllllllllllllllllcccclloxOOOOOOOOOOOOOOOkxdoooooooooooooooooooooooooodooodoooddddddddddddd    //
//    llllllllllllllllllllllllccclllllllllllllllllllllllccclxOOOOOOOOOOOOOkkxddooooooooooooooooooooooooooddooooodddddddddddddd    //
//    cclllllllllllllllllllllllllcccclllllllllllllllllllllclxOOOOOOOOOOOkkxxdddoooooooooooooooooooooooooddoooddddddddddddddddd    //
//    cccclllllllllllllllllllllllllccclllllllllllllllllllllokOOOOOOOOOkkxxxdddoooooooooooooooooooooooooooooodddddddddddddddddd    //
//    llccccclllllllllllllllllllllllllcccllllllllllllllllllokOOOOOOOkkkxxxddoolllloooooooooooooooooooooooodddddddddddddddddddd    //
//    lllllccccllllllllllllllllllllllllccccclllllllllllllllokOOOOkkkkxxxdddoollllllooooooooooooooooooooddddddddddddddddddddddd    //
//    llllllllccccllllllllllllllllllllllllcccclllllllllllllokOOkkkxxxdddooollllllllllooooooooooooooooddddddddddddddddddddddddd    //
//    llllllllllcccclllllllllllllllllllllllllcccllllllllllloxkkxxxdddolllllllllllllloooooooooooooooooddddddddddddddddddddddddd    //
//    lllllllllllllccccllllllllllllllllllllllllccccllllllllldxxxdooolccclllllllllllllooooooooooooooooodddddddddddddddddddddddd    //
//    llllllllllllllllccccllllloollllllllllllllllccccclllllldddolccc:ccccclllclllllllloooooooooooooooodddddddddddddddddddddddd    //
//    llllllllllllllllllccclllllllllllllllllllllllllcccccllllllc;;;;;:::cccccclllllllloooooooooodooooodddddddddddddddddddddddd    //
//    lllllllllllllllllllllccclllllllollllllllllllllllcccccc:;;,,,,,,;;::ccccccllllllllloooooooooooooodddddddddddddddddddddddd    //
//    lllllllllllllllllllllllccclllllolllllllllllllllllllcc:,''''''',,;;::cccccllllllllooooooooooooooodddddddddodddddddddddddd    //
//    lllllllllllllllllllllllllllcclloollolllllllllllllllllc'......'',,;;::ccccllclllloooooooooooooooddddddddodddddddddddddddd    //
//    cllllllllllllllllllllllllllllcclllooollllllllllllllllc' ......'',;;:::ccccccllloooooooooooooooodddddoddddddddddddddddddd    //
//    ccccllllllllllllllllolllllolllllccllllllllollllllllllc.  .....'',;;:::cccclllllloooooooooooooooooooooddddddddddddddddddd    //
//    lllccclllllllllllllloollllolllllllccclllllolloollllllc.   .....',,;::::ccllllllloooooooooooooooooooddddddddddddddddddddd    //
//    llllccccllllllllllllooooooolllllllllccccllolloollllllc.   .....',,;;::cccllllllllooooooooooooooooddddddddddddddddddddddd    //
//    llllllllccclllllllloolloooollllllllllllcccllloollllllc.    ....'',;;:ccccclllllllooooooooooooooddddddddddddddddddddddddd    //
//    lllllllllllcclllllloolloloollloollllllllllcccllllllllc.    .....',;:::cccclllllllooooooooooooodddddddddddddddddddddddddd    //
//    lllllllllllllccccllooooooooolloollllllllllllcccclllllc.    ....',,;:::cccclllllllooooooooooooodddddddddddddddddddddddddd    //
//    ollllollllllllllcclllooooooolloolllolllllllllllccccllc.    ....',,;;:::ccclllllllooooooooooooodddddddddddddddddddddddddd    //
//    oolllolllllllllllllclllooooooooolllllllllllllllllccccc.    ....'',;;:::ccclllllllllloooooooooodddddddddddddddddddddddddd    //
//    ooooooolllllllllloolllllllollooollllllllllollllllllcc:.    ....'',;;:::ccccllllllllooooooooooooddddddddddddddddddddddddd    //
//    oolooooooloooollllooolllllllloooloolllllllllloollllllc.    .....',,;:::ccccllllllloooooooooooooddddddddddddddddddddddddd    //
//    oooloooooooooolllloooooolllcllooloooolllllllllollllllc.    .....',,;:::ccccccllllooooooooooooooddddddddddddddddddddddddd    //
//    ooooooooloooooollloooooooollccllllooollllllllolllllllc.    .....',,;:::cccccllllloooooooooooooodddddddoddddddddddddddddd    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EAVES is ERC721Creator {
    constructor() ERC721Creator("Eaves", "EAVES") {}
}
