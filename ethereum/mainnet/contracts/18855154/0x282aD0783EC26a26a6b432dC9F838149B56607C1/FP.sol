// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Free Palestine
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////
//         //
//         //
//    .    //
//         //
//         //
/////////////


contract FP is ERC721Creator {
    constructor() ERC721Creator("Free Palestine", "FP") {}
}
