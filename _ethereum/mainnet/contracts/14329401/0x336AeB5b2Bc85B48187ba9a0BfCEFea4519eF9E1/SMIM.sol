
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Smiling Men
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//     _____                          .___                   //
//    _/ ____\______   ____   ____   __| _/____   _____      //
//    \   __\\_  __ \_/ __ \_/ __ \ / __ |/  _ \ /     \     //
//     |  |   |  | \/\  ___/\  ___// /_/ (  <_> )  Y Y  \    //
//     |__|   |__|    \___  >\___  >____ |\____/|__|_|  /    //
//                        \/     \/     \/            \/     //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract SMIM is ERC721Creator {
    constructor() ERC721Creator("The Smiling Men", "SMIM") {}
}
