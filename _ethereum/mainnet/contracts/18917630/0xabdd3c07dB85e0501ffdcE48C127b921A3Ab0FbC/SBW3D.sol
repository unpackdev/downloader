// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Steamboat Willie 3D
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    SBW3D    //
//             //
//             //
/////////////////


contract SBW3D is ERC721Creator {
    constructor() ERC721Creator("Steamboat Willie 3D", "SBW3D") {}
}
