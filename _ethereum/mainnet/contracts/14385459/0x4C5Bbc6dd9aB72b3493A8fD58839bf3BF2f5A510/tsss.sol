
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Snack Shop Specials
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    - The Snack Shop Specials -    //
//                                   //
//                                   //
///////////////////////////////////////


contract tsss is ERC721Creator {
    constructor() ERC721Creator("The Snack Shop Specials", "tsss") {}
}
