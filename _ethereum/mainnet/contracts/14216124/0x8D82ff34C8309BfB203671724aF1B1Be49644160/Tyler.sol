
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tyler
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                                               //
//    88888888888       888                      //
//        888           888                      //
//        888           888                      //
//        888  888  888 888  .d88b.  888d888     //
//        888  888  888 888 d8P  Y8b 888P"       //
//        888  888  888 888 88888888 888         //
//        888  Y88b 888 888 Y8b.     888         //
//        888   "Y88888 888  "Y8888  888         //
//                  888                          //
//             Y8b d88P                          //
//              "Y88P"                           //
//                                               //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract Tyler is ERC721Creator {
    constructor() ERC721Creator("Tyler", "Tyler") {}
}
