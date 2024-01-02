// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GOLD
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//     GOLD    //
//             //
//             //
//             //
/////////////////


contract GOLD is ERC721Creator {
    constructor() ERC721Creator("GOLD", "GOLD") {}
}
