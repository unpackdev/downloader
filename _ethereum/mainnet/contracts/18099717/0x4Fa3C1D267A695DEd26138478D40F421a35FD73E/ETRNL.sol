// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eternal
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//    ETERNAL    //
//               //
//               //
///////////////////


contract ETRNL is ERC721Creator {
    constructor() ERC721Creator("Eternal", "ETRNL") {}
}
