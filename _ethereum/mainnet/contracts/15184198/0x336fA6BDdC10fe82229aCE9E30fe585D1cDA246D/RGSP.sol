
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Roman Gutikov Springs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//                                                             //
//           ______  _____  _______ _______ __   _             //
//          |_____/ |     | |  |  | |_____| | \  |             //
//          |    \_ |_____| |  |  | |     | |  \_|             //
//                                                             //
//      ______ _     _ _______ _____ _     _  _____  _    _    //
//     |  ____ |     |    |      |   |____/  |     |  \  /     //
//     |_____| |_____|    |    __|__ |    \_ |_____|   \/      //
//                                                             //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract RGSP is ERC721Creator {
    constructor() ERC721Creator("Roman Gutikov Springs", "RGSP") {}
}
