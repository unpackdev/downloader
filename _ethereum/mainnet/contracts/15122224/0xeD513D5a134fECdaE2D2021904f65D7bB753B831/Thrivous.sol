
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Thrivous
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//                                                                     //
//     _______ _     _  ______ _____ _    _  _____  _     _ _______    //
//        |    |_____| |_____/   |    \  /  |     | |     | |______    //
//        |    |     | |    \_ __|__   \/   |_____| |_____| ______|    //
//                                                                     //
//                                                                     //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract Thrivous is ERC721Creator {
    constructor() ERC721Creator("Thrivous", "Thrivous") {}
}
