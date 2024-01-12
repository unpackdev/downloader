
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Zeedest
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//     _   _         ___  _________  ____   __    //
//    | \ | |       / _ \ | ___ \  \/  \ \ / /    //
//    |  \| |______/ /_\ \| |_/ / .  . |\ V /     //
//    | . ` |______|  _  ||    /| |\/| | \ /      //
//    | |\  |      | | | || |\ \| |  | | | |      //
//    \_| \_/      \_| |_/\_| \_\_|  |_/ \_/      //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract NZA is ERC721Creator {
    constructor() ERC721Creator("Zeedest", "NZA") {}
}
