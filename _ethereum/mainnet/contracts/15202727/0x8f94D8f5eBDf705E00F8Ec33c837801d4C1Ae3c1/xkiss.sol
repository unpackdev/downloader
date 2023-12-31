
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Study 1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                  //
//                                                                                                                  //
//     ________  _______   ________  _______   ________           ___       ________  ___      ___ _______          //
//    |\   ___ \|\  ___ \ |\   ____\|\  ___ \ |\   ___  \        |\  \     |\   __  \|\  \    /  /|\  ___ \         //
//    \ \  \_|\ \ \   __/|\ \  \___|\ \   __/|\ \  \\ \  \       \ \  \    \ \  \|\  \ \  \  /  / | \   __/|        //
//     \ \  \ \\ \ \  \_|/_\ \  \  __\ \  \_|/_\ \  \\ \  \       \ \  \    \ \  \\\  \ \  \/  / / \ \  \_|/__      //
//      \ \  \_\\ \ \  \_|\ \ \  \|\  \ \  \_|\ \ \  \\ \  \       \ \  \____\ \  \\\  \ \    / /   \ \  \_|\ \     //
//       \ \_______\ \_______\ \_______\ \_______\ \__\\ \__\       \ \_______\ \_______\ \__/ /     \ \_______\    //
//        \|_______|\|_______|\|_______|\|_______|\|__| \|__|        \|_______|\|_______|\|__|/       \|_______|    //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract xkiss is ERC721Creator {
    constructor() ERC721Creator("Study 1", "xkiss") {}
}
