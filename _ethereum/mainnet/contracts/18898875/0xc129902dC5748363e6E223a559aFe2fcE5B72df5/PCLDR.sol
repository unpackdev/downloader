// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Porcelain Dreams
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


contract PCLDR is ERC721Creator {
    constructor() ERC721Creator("Porcelain Dreams", "PCLDR") {}
}
