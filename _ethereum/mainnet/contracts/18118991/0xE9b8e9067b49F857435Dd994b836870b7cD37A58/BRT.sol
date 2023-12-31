// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BRV5I
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    BRV5I    //
//             //
//             //
/////////////////


contract BRT is ERC721Creator {
    constructor() ERC721Creator("BRV5I", "BRT") {}
}
