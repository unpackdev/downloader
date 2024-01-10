
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OBF
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    hello    //
//             //
//             //
/////////////////


contract OBF is ERC721Creator {
    constructor() ERC721Creator("OBF", "OBF") {}
}
