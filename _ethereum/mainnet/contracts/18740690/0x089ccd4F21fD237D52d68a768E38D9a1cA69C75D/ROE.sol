// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rhythms of Empathy
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    ***Rhythms of Empathy***    //
//                                //
//                                //
////////////////////////////////////


contract ROE is ERC721Creator {
    constructor() ERC721Creator("Rhythms of Empathy", "ROE") {}
}
