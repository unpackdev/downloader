
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TEST1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    TEST    //
//            //
//            //
////////////////


contract T11 is ERC721Creator {
    constructor() ERC721Creator("TEST1", "T11") {}
}
