
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fashionista
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    ____    ____  ______    _______       _______.    //
//    \   \  /   / /  __  \  |       \     /       |    //
//     \   \/   / |  |  |  | |  .--.  |   |   (----`    //
//      \_    _/  |  |  |  | |  |  |  |    \   \        //
//        |  |    |  `--'  | |  '--'  |.----)   |       //
//        |__|     \______/  |_______/ |_______/        //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract YODS is ERC721Creator {
    constructor() ERC721Creator("Fashionista", "YODS") {}
}
