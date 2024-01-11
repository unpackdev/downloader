
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LOK
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    Loker    //
//             //
//             //
/////////////////


contract LOK is ERC721Creator {
    constructor() ERC721Creator("LOK", "LOK") {}
}
