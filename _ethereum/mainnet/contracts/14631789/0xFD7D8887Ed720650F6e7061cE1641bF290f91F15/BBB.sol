
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BubbleBOY
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    BubbleBOY by sodabubble.eth    //
//                                   //
//                                   //
///////////////////////////////////////


contract BBB is ERC721Creator {
    constructor() ERC721Creator("BubbleBOY", "BBB") {}
}
