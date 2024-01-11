
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Kiss
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    CC-THE-KISS    //
//                   //
//                   //
///////////////////////


contract CCKIS is ERC721Creator {
    constructor() ERC721Creator("The Kiss", "CCKIS") {}
}
