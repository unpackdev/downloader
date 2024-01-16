
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Viniclou Gifts
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//      ________.__  _____  __       //
//     /  _____/|__|/ ____\/  |_     //
//    /   \  ___|  \   __\\   __\    //
//    \    \_\  \  ||  |   |  |      //
//     \______  /__||__|   |__|      //
//            \/                     //
//                                   //
//                                   //
///////////////////////////////////////


contract Vini is ERC721Creator {
    constructor() ERC721Creator("Viniclou Gifts", "Vini") {}
}
