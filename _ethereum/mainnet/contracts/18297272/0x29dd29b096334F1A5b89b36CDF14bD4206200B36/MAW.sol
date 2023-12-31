// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MagicalAiWorld
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////
//         //
//         //
//    .    //
//         //
//         //
/////////////


contract MAW is ERC721Creator {
    constructor() ERC721Creator("MagicalAiWorld", "MAW") {}
}
