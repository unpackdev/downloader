
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Slide
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    We want everythind Slide.    //
//                                 //
//                                 //
/////////////////////////////////////


contract SLD is ERC721Creator {
    constructor() ERC721Creator("Slide", "SLD") {}
}
