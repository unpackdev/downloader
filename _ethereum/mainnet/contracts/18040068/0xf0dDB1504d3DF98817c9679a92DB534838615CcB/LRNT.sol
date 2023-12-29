// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: lrntngn
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    .__                __                             //
//    |  |_______  _____/  |_  ____    ____   ____      //
//    |  |\_  __ \/    \   __\/    \  / ___\ /    \     //
//    |  |_|  | \/   |  \  | |   |  \/ /_/  >   |  \    //
//    |____/__|  |___|  /__| |___|  /\___  /|___|  /    //
//                    \/          \//_____/      \/     //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract LRNT is ERC721Creator {
    constructor() ERC721Creator("lrntngn", "LRNT") {}
}
