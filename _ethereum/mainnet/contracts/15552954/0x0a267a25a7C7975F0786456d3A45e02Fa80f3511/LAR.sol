
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: lines & ripples
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//                                  //
//     ██▓    ▄▄▄       ██▀███      //
//    ▓██▒   ▒████▄    ▓██ ▒ ██▒    //
//    ▒██░   ▒██  ▀█▄  ▓██ ░▄█ ▒    //
//    ▒██░   ░██▄▄▄▄██ ▒██▀▀█▄      //
//    ░██████▒▓█   ▓██▒░██▓ ▒██▒    //
//    ░ ▒░▓  ░▒▒   ▓▒█░░ ▒▓ ░▒▓░    //
//    ░ ░ ▒  ░ ▒   ▒▒ ░  ░▒ ░ ▒░    //
//      ░ ░    ░   ▒     ░░   ░     //
//        ░  ░     ░  ░   ░         //
//                                  //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract LAR is ERC721Creator {
    constructor() ERC721Creator("lines & ripples", "LAR") {}
}
