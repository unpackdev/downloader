
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alice's Garden
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////
//         //
//         //
//    ●    //
//         //
//         //
/////////////


contract IOI is ERC721Creator {
    constructor() ERC721Creator("Alice's Garden", "IOI") {}
}
