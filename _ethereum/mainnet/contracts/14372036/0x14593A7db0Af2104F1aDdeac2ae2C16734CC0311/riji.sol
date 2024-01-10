
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 日记
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    羊肉串好吃    //
//             //
//             //
/////////////////


contract riji is ERC721Creator {
    constructor() ERC721Creator(unicode"日记", "riji") {}
}
