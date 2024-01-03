// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0773H_World.exe
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                      _           //
//      __ _ _ __ __ _ _ __ ___   __ _ (_) ___      //
//     / _` | '__/ _` | '_ ` _ \ / _` || |/ _ \     //
//    | (_| | | | (_| | | | | | | (_| || | (_) |    //
//     \__, |_|  \__,_|_| |_| |_|\__,_|/ |\___/     //
//     |___/                         |__/           //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract HELO is ERC1155Creator {
    constructor() ERC1155Creator("0773H_World.exe", "HELO") {}
}
