
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Museum of Peter (MoP)
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//     ██▓███  ▄▄▄█████▓ ██▀███      //
//    ▓██░  ██▒▓  ██▒ ▓▒▓██ ▒ ██▒    //
//    ▓██░ ██▓▒▒ ▓██░ ▒░▓██ ░▄█ ▒    //
//    ▒██▄█▓▒ ▒░ ▓██▓ ░ ▒██▀▀█▄      //
//    ▒██▒ ░  ░  ▒██▒ ░ ░██▓ ▒██▒    //
//    ▒▓▒░ ░  ░  ▒ ░░   ░ ▒▓ ░▒▓░    //
//    ░▒ ░         ░      ░▒ ░ ▒░    //
//    ░░         ░        ░░   ░     //
//                         ░         //
//                                   //
//                                   //
///////////////////////////////////////


contract MoP is ERC721Creator {
    constructor() ERC721Creator("The Museum of Peter (MoP)", "MoP") {}
}
