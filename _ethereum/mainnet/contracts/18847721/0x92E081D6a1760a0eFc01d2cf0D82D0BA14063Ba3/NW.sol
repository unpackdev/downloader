// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Neoki World
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    NEOKI WORLD     //
//                    //
//                    //
////////////////////////


contract NW is ERC721Creator {
    constructor() ERC721Creator("Neoki World", "NW") {}
}
