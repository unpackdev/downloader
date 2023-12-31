// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: jun._.ka
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒░    //
//    ▒▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░▒▒▒▒▒▒▒▒▒▒░░░░░    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▓▓▓▓▓▓▓▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒░░░░░░    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▓▓▓▓▓▓▓▓▓▓▒░░░░░▒▒▒▒▒░░░░░░░░░░░▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒░▒▒▒▒▒▒▒▒▒▒░░░░░░░    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▒▒░▒▒▒▒▒░░░░░░░░    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░▒▒▒▒▒░░▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▓▒░░░░░░░░░    //
//    ▓▓▓▓▓▓▓▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒░▒▒▒▒▒░░▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░    //
//    ▒▓▓▓▓▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░    //
//    ░▒▓▓▒▒▒▒░▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░░░░░▒▒▒▒▒▒░░░░░░▒▒▒▒▒░░░░▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░    //
//    ░░░▒▒▒░░░░░▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒░░░░░░░▒▒░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░    //
//    ░░░░▒▒▒░░░▒▒▒▓▓▓▓▓▓▓▓▓▓▓▒░░░▒▒░░░░▓▓░░░░░░░░░░░░░░░░░░░▒░░░▓▓▒░▒▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░    //
//    ░░░░░░▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▒░░░░▒▒░░░░▒▓▓▓░░░░░░░░░░░░░░░░░▒░░░░▓▓▓▒░░▒▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░    //
//    ░░░░░░░▒▒▒▓▓▓▓▓▓▓▓▓▓▒▒░░░░░▓▓▒▒▓▓▓▓▓▓░░░░░░░░░░░░░░░░░▒▓▒▓▓▓▓▓▓░░░▒▓▓▓▒▒▒░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░▒▒▒▒▓▓▓▒▒▒▒░░░░░░▓▒░░▓▓▓▒▓▒░░░░░░░░░░░░░░░░░░▓░░▓▓▓▒▓░░░░▒▒▒░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░▓▒▒▒▒▒░░░░░░░▒▓▒▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░▒▓▓▓▓▒▒▒░░░░░▒▒▒░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░▒▒▒▒▒▒░░░░░░░░░░░▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░░░░░▒▒▒░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░▒▒▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░▒▒▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░▒▒▒▒▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░▒░░▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░▒▒▒░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░▒▒▒▒░░░░░░░░░▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░▒▒▒▒▒▒░░░░░░░░░░░░▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract JUNKA is ERC721Creator {
    constructor() ERC721Creator("jun._.ka", "JUNKA") {}
}
