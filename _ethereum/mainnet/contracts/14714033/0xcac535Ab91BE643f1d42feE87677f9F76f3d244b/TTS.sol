
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: To The Scarf
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//      __  .__            _____                        //
//    _/  |_|  |__   _____/ ____\____  __ _________     //
//    \   __\  |  \_/ __ \   __\/  _ \|  |  \_  __ \    //
//     |  | |   Y  \  ___/|  | (  <_> )  |  /|  | \/    //
//     |__| |___|  /\___  >__|  \____/|____/ |__|       //
//               \/     \/                              //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract TTS is ERC721Creator {
    constructor() ERC721Creator("To The Scarf", "TTS") {}
}
