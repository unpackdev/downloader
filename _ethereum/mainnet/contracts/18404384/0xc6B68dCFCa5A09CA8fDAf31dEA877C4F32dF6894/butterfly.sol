// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: butterfly
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////
//         //
//         //
//         //
//         //
//         //
/////////////


contract butterfly is ERC721Creator {
    constructor() ERC721Creator("butterfly", "butterfly") {}
}
