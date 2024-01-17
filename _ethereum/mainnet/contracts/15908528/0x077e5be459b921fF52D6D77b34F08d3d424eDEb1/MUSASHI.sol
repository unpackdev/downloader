
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rise of Musashi
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Rise of Musashi    //
//                       //
//                       //
///////////////////////////


contract MUSASHI is ERC721Creator {
    constructor() ERC721Creator("Rise of Musashi", "MUSASHI") {}
}
