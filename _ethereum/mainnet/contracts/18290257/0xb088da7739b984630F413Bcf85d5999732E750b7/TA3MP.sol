// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Trippin Ape 3D Mint Pass
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    TA3MP    //
//             //
//             //
/////////////////


contract TA3MP is ERC721Creator {
    constructor() ERC721Creator("Trippin Ape 3D Mint Pass", "TA3MP") {}
}
