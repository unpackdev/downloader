
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test Contract
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    This is a test contract    //
//                               //
//                               //
///////////////////////////////////


contract TST12345 is ERC721Creator {
    constructor() ERC721Creator("Test Contract", "TST12345") {}
}
