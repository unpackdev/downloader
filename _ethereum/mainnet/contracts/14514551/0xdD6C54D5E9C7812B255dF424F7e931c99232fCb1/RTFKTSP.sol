
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RTFKT Space Pod
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    RTFKT Space Pod    //
//                       //
//                       //
///////////////////////////


contract RTFKTSP is ERC721Creator {
    constructor() ERC721Creator("RTFKT Space Pod", "RTFKTSP") {}
}
