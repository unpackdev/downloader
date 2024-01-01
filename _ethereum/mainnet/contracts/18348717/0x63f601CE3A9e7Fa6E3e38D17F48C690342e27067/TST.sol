// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TEST
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    TEST    //
//            //
//            //
////////////////


contract TST is ERC721Creator {
    constructor() ERC721Creator("TEST", "TST") {}
}
