
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: World of Women Galaxy
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    World of Women Galaxy    //
//                             //
//                             //
/////////////////////////////////


contract WOWG is ERC721Creator {
    constructor() ERC721Creator("World of Women Galaxy", "WOWG") {}
}
