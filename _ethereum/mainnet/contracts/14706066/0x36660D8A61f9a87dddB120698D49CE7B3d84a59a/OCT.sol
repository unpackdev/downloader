
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cyber Tutorials
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    Tutorials to use oncyber.    //
//                                 //
//                                 //
/////////////////////////////////////


contract OCT is ERC721Creator {
    constructor() ERC721Creator("Cyber Tutorials", "OCT") {}
}
