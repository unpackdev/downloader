// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Builders Box
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    The Builders Box - The Builders Dao    //
//                                           //
//                                           //
///////////////////////////////////////////////


contract TBB is ERC721Creator {
    constructor() ERC721Creator("The Builders Box", "TBB") {}
}
