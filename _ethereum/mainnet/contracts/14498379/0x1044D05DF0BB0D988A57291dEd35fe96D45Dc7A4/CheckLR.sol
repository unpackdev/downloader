
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Check LooksRare
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    Check your offers on LooksRare     //
//                                       //
//                                       //
///////////////////////////////////////////


contract CheckLR is ERC721Creator {
    constructor() ERC721Creator("Check LooksRare", "CheckLR") {}
}
