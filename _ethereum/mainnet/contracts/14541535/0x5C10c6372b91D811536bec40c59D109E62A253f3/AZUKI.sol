
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Azuki #1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    Azuki    //
//             //
//             //
/////////////////


contract AZUKI is ERC721Creator {
    constructor() ERC721Creator("Azuki #1", "AZUKI") {}
}
