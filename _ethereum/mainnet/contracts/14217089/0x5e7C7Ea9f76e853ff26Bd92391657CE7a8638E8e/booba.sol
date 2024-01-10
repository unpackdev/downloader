
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: booba
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    booba    //
//             //
//             //
/////////////////


contract booba is ERC721Creator {
    constructor() ERC721Creator("booba", "booba") {}
}
