// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ghostly Mice
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Ghostly Mice    //
//                    //
//                    //
////////////////////////


contract GNM is ERC721Creator {
    constructor() ERC721Creator("Ghostly Mice", "GNM") {}
}
