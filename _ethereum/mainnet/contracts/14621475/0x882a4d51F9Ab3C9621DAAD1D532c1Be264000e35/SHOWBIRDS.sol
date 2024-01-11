
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ShowBirds
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//      __________       //
//     / ___  ___ \      //
//    / / @ \/ @ \ \     //
//    \ \___/\___/ /\    //
//     \____\/____/||    //
//     /     /\\\\\//    //
//    |     |\\\\\\      //
//     \      \\\\\\     //
//       \______/\\\\    //
//        _||_||_        //
//                       //
//                       //
///////////////////////////


contract SHOWBIRDS is ERC721Creator {
    constructor() ERC721Creator("ShowBirds", "SHOWBIRDS") {}
}
