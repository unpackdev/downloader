
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shred the Nouns
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                                                             //
//    MMMMMMMMMMM0'    .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMM0'    .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    00000000000d.    .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                     .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                     .dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//          ......      lKKKKKKKKKKKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//         'kKKKKx.      ...........:XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//         ;XMMMM0'                 ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//         :0NNNNk.                 'ONNNNNNNNNNNNWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    00000d,.....      cOO00O:      ............,kWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMx.          .dWMMMWo                   oWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMk.          .dWWWWNo                   oNWWWWWWWWWWWMMMMMMMMMMMM    //
//    MMMMMXOkkkkkkkkkkxc;,,,,.     .okkkkko.     .,,,,,,,,,,,lXMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMX:           ,KMMMMMK,                 '0MMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMX:           ,KMMMMMK,                 '0MMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWOdddddddddddoc:::::;.     ,odddd;     .,:::::::::::    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.            oWMMMMd.                     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.            oWMMMMd.                     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKdlllllllllllo0WMMMMd.    .:llll:.         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd.    '0MMMMX;         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd.    '0MMMMX;         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0l::::dXMMMMX;         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;         //
//                                                                             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////


contract DOOM is ERC721Creator {
    constructor() ERC721Creator("Shred the Nouns", "DOOM") {}
}
