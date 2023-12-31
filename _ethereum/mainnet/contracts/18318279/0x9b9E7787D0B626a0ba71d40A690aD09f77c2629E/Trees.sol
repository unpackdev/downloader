// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Study of Trees
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    TREES    //
//             //
//             //
/////////////////


contract Trees is ERC721Creator {
    constructor() ERC721Creator("A Study of Trees", "Trees") {}
}
