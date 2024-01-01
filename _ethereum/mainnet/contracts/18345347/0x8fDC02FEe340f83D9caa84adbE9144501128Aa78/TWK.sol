// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Twerk
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    TWERK    //
//             //
//             //
/////////////////


contract TWK is ERC721Creator {
    constructor() ERC721Creator("Twerk", "TWK") {}
}
