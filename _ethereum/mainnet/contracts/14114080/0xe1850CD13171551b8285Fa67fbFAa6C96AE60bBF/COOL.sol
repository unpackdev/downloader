
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cool Pets
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////
//         //
//         //
//         //
//         //
//         //
/////////////


contract COOL is ERC721Creator {
    constructor() ERC721Creator("Cool Pets", "COOL") {}
}
