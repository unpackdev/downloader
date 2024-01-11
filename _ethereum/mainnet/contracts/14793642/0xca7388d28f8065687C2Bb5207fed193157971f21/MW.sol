
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mystical Women
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    Mystical Women Collection    //
//                                 //
//                                 //
/////////////////////////////////////


contract MW is ERC721Creator {
    constructor() ERC721Creator("Mystical Women", "MW") {}
}
