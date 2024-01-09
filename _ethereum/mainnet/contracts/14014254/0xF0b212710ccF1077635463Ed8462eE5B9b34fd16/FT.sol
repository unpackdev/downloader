
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Floating Thoughts
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//                          //
//     _______ _________    //
//    (  ____ \\__   __/    //
//    | (    \/   ) (       //
//    | (__       | |       //
//    |  __)      | |       //
//    | (         | |       //
//    | )         | |       //
//    |/          )_(       //
//                          //
//                          //
//                          //
//                          //
//                          //
//                          //
//                          //
//                          //
//                          //
//                          //
//                          //
//                          //
//                          //
//////////////////////////////


contract FT is ERC721Creator {
    constructor() ERC721Creator("Floating Thoughts", "FT") {}
}
