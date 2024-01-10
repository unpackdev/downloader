
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WONDERPALS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    WONDERPALS    //
//                  //
//                  //
//////////////////////


contract WP is ERC721Creator {
    constructor() ERC721Creator("WONDERPALS", "WP") {}
}
