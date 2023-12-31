// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Visions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//    Visions    //
//               //
//               //
///////////////////


contract VIS is ERC721Creator {
    constructor() ERC721Creator("Visions", "VIS") {}
}
