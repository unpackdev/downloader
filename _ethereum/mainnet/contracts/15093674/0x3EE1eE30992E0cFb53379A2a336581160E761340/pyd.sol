
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Playbard
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    No one doesn't like to be in a daze    //
//                                           //
//                                           //
///////////////////////////////////////////////


contract pyd is ERC721Creator {
    constructor() ERC721Creator("Playbard", "pyd") {}
}
