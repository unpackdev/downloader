
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BeatBalls
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    IMAKEBEATS    //
//                  //
//                  //
//////////////////////


contract BEATS is ERC721Creator {
    constructor() ERC721Creator("BeatBalls", "BEATS") {}
}
