
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PXLMYSTIC v0
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    PXLMYSTIC v0    //
//                    //
//                    //
////////////////////////


contract MYSTC is ERC721Creator {
    constructor() ERC721Creator("PXLMYSTIC v0", "MYSTC") {}
}
