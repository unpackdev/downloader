
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WTF
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//     __      ________________________    //
//    /  \    /  \__    ___/\_   _____/    //
//    \   \/\/   / |    |    |    __)      //
//     \        /  |    |    |     \       //
//      \__/\  /   |____|    \___  /       //
//           \/                  \/        //
//                                         //
//                                         //
/////////////////////////////////////////////


contract Broke is ERC721Creator {
    constructor() ERC721Creator("WTF", "Broke") {}
}
