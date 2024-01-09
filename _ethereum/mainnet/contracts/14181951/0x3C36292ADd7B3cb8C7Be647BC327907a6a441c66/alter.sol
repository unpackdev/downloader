
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Billie Alter Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Billie Alter    //
//                    //
//                    //
////////////////////////


contract alter is ERC721Creator {
    constructor() ERC721Creator("Billie Alter Editions", "alter") {}
}
