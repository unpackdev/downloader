// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Thug Life Mouse
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    collindyer.eth    //
//                      //
//                      //
//////////////////////////


contract TLM is ERC721Creator {
    constructor() ERC721Creator("Thug Life Mouse", "TLM") {}
}
