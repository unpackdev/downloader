// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: To Migrate
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    CLOSE    //
//             //
//             //
/////////////////


contract MIGRATE is ERC721Creator {
    constructor() ERC721Creator("To Migrate", "MIGRATE") {}
}
