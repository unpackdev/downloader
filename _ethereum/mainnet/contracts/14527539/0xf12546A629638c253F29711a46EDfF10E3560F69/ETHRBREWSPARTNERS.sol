
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ETH.r Brews Partner Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                    //
//                                                                                                                                                    //
//    /*                                                                                                                                              //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMWWMWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWX0XWWNMMMWWMMMMMMMMMMMMMMMMMMMMMWWNNNXXXKKXNWMMMMWWMMMWMWMMMMMMMMMMMMMMMMMMNKK00OkOXMMWOllcc::oXWWWWWWWWWWWWWWWWWWMMMMMMMMMM    //
//    MMMMMMMMMMMMMMXo,,,;;dNMO:,;;::ccllooddxkOXWWk:;,,''.......':dXMMNOxxkkkkOO0000klcc::;:OMM0;...    cNMK,      '0WNK0OkkOO0XWWWWWWWWMMMMMMMMM    //
//    MMMMMMMMMMMMMMO..:. ;OWMo                 .cOc                ;0MO'         ...        cNMx.       'OMO.      ,ko,.      ..,cxKWWWWWMMMMMMMM    //
//    MMMMMMMMMMMMMMXdlcc::kWWc     ...  ..       ..       .l:       lWk.                    '0Md         oWk.       .              .dNWWWWMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMOcOMWd,,':xKKxook0c               :KO,      ;Xx.       .:lcc:'      .dWl         ;Xx.             .lO:      '0WWWWMMMMMMM    //
//    MMMMMMMMMMMMMMOlloolc0MXc...;dOOxxx0Xl.              .cc.      cNd        ;XMMMM0,      cXc         .Od              .OWd.     .OWWWWWMMMMMM    //
//    MMMMMMMMMMMMMM0d: .cdKM0'       .:co:       'c.              .c0Wo        ,OKKXWWl      'Oc          oo               'dkkxddolkNWWWWWMMMMMM    //
//    MMMMMMMMMMMMMNx:' .lkNMk.                .'lKK;              .l0Nc         ....xWO'     .l;          ,;       cc.       .;dKWWWWWWWWWWWMMMMM    //
//    MMMMMMMMMMMMMXocddddONMx.                cKMMN:        .       .kc             oWNc      .     .;.           .kWOl.        .cONWWWWWWWWMMMMM    //
//    MMMMMMMMMMMMMO.'dkkOXMMo                  'xNWl       :Ko.      c;        ,olloKMMk.           :0:           .dXXNKx:.       .oNWWWWWWWMMMMM    //
//    MMMMMMMMMMMMMx..::::kWWx'..'cxxxdc;c:.      lNo       :N0,      ..       .xMWMMMMMN:           cNx.           ...',;d0o.      .kWWWWWWWMMMMM    //
//    MMMMMMMMMMMMMOckMMNXWMNd'',:xKNWXOkKXo.     '0x.      ,KX;               .kMWMMMMMMx.          oWX:                 :XWl      .dWWWWWWWMMMMM    //
//    MMMMMMMMMMMMMo'oodo,kMK;     .''',;,'.      ;Xk.      '0Nc                ';:::xNMMX;         .xMWk.                :XK;      .kWWWWWWWMMMMM    //
//    MMMMMMMMMMMMWo......kM0'                   ;0M0'      ,0Wx'.''',.              ;KMMWd.      ..;0MMNx;;::ccllol'      ..       :XWWWWWWWMMMMM    //
//    MMMMMMMMMMMMMN00OOk0NMNxlcc::;;,'''.....'cxNMMW0xxkOOOKWMWNXNNWW0c;,,'''''.....lNMMMNkxxkkO00KXWMMMMMMMMMMMMMWXx:..        .'lKWWWWWWWWMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNXXKXWMMMMMMMMMMMMMMMMWMMMMMMWWWWWWWNNNNXXXXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMWN0kxdooodx0XWWWWWWWWWWMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWWMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWMMMMMM    //
//    */                                                                                                                                              //
//                                                                                                                                                    //
//                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ETHRBREWSPARTNERS is ERC721Creator {
    constructor() ERC721Creator("ETH.r Brews Partner Collection", "ETHRBREWSPARTNERS") {}
}
