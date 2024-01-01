// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lucid Morphics  by MVW
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//     _____ ______   ___      ___ ___       __          //
//    |\   _ \  _   \|\  \    /  /|\  \     |\  \        //
//    \ \  \\\__\ \  \ \  \  /  / | \  \    \ \  \       //
//     \ \  \\|__| \  \ \  \/  / / \ \  \  __\ \  \      //
//      \ \  \    \ \  \ \    / /   \ \  \|\__\_\  \     //
//       \ \__\    \ \__\ \__/ /     \ \____________\    //
//        \|__|     \|__|\|__|/       \|____________|    //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract LUMO is ERC721Creator {
    constructor() ERC721Creator("Lucid Morphics  by MVW", "LUMO") {}
}
