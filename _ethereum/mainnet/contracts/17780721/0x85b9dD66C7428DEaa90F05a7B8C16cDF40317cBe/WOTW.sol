// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Whispers Of The Winged
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//     __      _______________________      __     //
//    /  \    /  \_____  \__    ___/  \    /  \    //
//    \   \/\/   //   |   \|    |  \   \/\/   /    //
//     \        //    |    \    |   \        /     //
//      \__/\  / \_______  /____|    \__/\  /      //
//           \/          \/               \/       //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract WOTW is ERC721Creator {
    constructor() ERC721Creator("Whispers Of The Winged", "WOTW") {}
}
